import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OCR_MODEL = Deno.env.get("OPENAI_OCR_MODEL") ?? "gpt-4.1-mini";
const PARSER_MODEL = Deno.env.get("OPENAI_PARSER_MODEL") ?? OCR_MODEL;
const INTAKE_BUCKET = Deno.env.get("LEAD_INTAKE_BUCKET") ?? "lead-intake-images";

type IntakeRequest = {
  bucket: string;
  objectPath: string;
  fileName: string;
  mimeType: string;
};

type ExtractionResponse = {
  draft: Record<string, string | boolean | null>;
  fieldConfidences: Array<{ fieldName: string; confidence: number }>;
  rawText: string;
};

const jsonHeaders = { "Content-Type": "application/json" };

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return respond(405, { error: "Use POST for lead image intake." });
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return respond(500, { error: "Supabase environment variables are not configured." });
  }

  if (!OPENAI_API_KEY) {
    return respond(500, { error: "OPENAI_API_KEY is missing from Edge Function secrets." });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return respond(401, { error: "Missing Authorization bearer token." });
  }

  const token = authHeader.replace("Bearer ", "");
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  try {
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser(token);

    if (userError || !user) {
      console.error("auth_get_user_failed", userError);
      return respond(401, {
        error: userError?.message ?? "The request token is invalid or expired.",
      });
    }

    const { data: profile, error: profileError } = await adminClient
      .from("app_users")
      .select("id, role")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      console.error("app_user_lookup_failed", profileError);
      return respond(403, { error: "The authenticated app user profile could not be loaded." });
    }

    if (profile.role !== "door_knocker") {
      return respond(403, { error: "Only door knockers can use image intake." });
    }

    const body = (await req.json()) as Partial<IntakeRequest>;
    const payload = validateRequest(body);

    if (payload.bucket != INTAKE_BUCKET) {
      return respond(400, { error: `Bucket ${payload.bucket} is not allowed for intake.` });
    }

    if (!payload.objectPath.startsWith(`${user.id}/`)) {
      return respond(403, { error: "You can only process images uploaded under your own intake path." });
    }

    const { data: objectBlob, error: downloadError } = await adminClient.storage
      .from(payload.bucket)
      .download(payload.objectPath);

    if (downloadError || !objectBlob) {
      console.error("storage_download_failed", downloadError);
      return respond(404, { error: "The uploaded intake image could not be downloaded." });
    }

    const imageBytes = new Uint8Array(await objectBlob.arrayBuffer());
    const rawText = (await performOCR(imageBytes, payload.mimeType)).trim();
    if (!rawText) {
      return respond(422, { error: "OCR could not find readable lead details in that image." });
    }

    const extraction = await parseLeadFields(rawText);
    const response: ExtractionResponse = {
      draft: normalizeDraft(extraction.draft, rawText),
      fieldConfidences: normalizeFieldConfidences(extraction.fieldConfidences),
      rawText,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: jsonHeaders,
    });
  } catch (error) {
    console.error("lead_image_intake_failed", error);
    const message = error instanceof Error ? error.message : "Lead image intake failed.";
    return respond(500, { error: message });
  }
});

function validateRequest(payload: Partial<IntakeRequest>): IntakeRequest {
  if (!payload.bucket || !payload.objectPath || !payload.fileName || !payload.mimeType) {
    throw new Error("bucket, objectPath, fileName, and mimeType are required.");
  }

  if (!payload.mimeType.startsWith("image/")) {
    throw new Error("Only image uploads can be processed.");
  }

  return {
    bucket: payload.bucket,
    objectPath: payload.objectPath,
    fileName: payload.fileName,
    mimeType: payload.mimeType,
  };
}

async function performOCR(imageBytes: Uint8Array, mimeType: string): Promise<string> {
  const imageDataURL = `data:${mimeType};base64,${encodeBase64(imageBytes)}`;
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: OCR_MODEL,
      temperature: 0,
      messages: [
        {
          role: "system",
          content:
            "You are an OCR engine for solar sales field notes. Transcribe visible text faithfully. Do not summarize, infer, or correct unclear text. Preserve numbers, phone digits, addresses, and line breaks whenever possible. Return only plain text.",
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                "Read this note image and return a plain text transcription of the homeowner name, phone, property address, city, state, ZIP, utility, appointment details, and any extra notes. Preserve line breaks when useful. If handwriting is unclear, keep the uncertain text rather than rewriting it.",
            },
            {
              type: "image_url",
              image_url: {
                url: imageDataURL,
                detail: "high",
              },
            },
          ],
        },
      ],
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    console.error("openai_ocr_failed", payload);
    throw new Error("OCR processing failed at the AI provider.");
  }

  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || !content.trim()) {
    throw new Error("OCR returned an empty response.");
  }

  return content;
}

async function parseLeadFields(rawText: string): Promise<{
  draft: Record<string, string | boolean | null>;
  fieldConfidences: Array<{ fieldName: string; confidence: number }>;
}> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: PARSER_MODEL,
      temperature: 0,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content:
            "Convert OCR text from solar sales field notes into structured JSON. Never invent data. Use null for unknown values. Keep booleans null when the OCR does not support a confident yes or no. Split the address carefully into street address, city, state, and ZIP when the OCR provides enough evidence. Return exactly one JSON object with keys draft and fieldConfidences.",
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                `Map the OCR transcript into this JSON shape:
{
  "draft": {
    "homeownerFullName": string | null,
    "phoneNumber": string | null,
    "email": string | null,
    "propertyAddress": string | null,
    "city": string | null,
    "state": string | null,
    "zipCode": string | null,
    "utilityCompany": string | null,
    "notes": string | null,
    "homeownerType": string | null,
    "averageElectricBill": string | null,
    "roofType": string | null,
    "shadingNotes": string | null,
    "decisionMakerPresent": boolean | null,
    "spousePresentRequired": boolean | null,
    "languagePreference": string | null
  },
  "fieldConfidences": [
    { "fieldName": string, "confidence": number }
  ]
}

Field names should match the draft keys exactly.
Confidence must be between 0 and 1.
Use notes to capture meaningful context that does not fit another field.
If the transcript contains a full address on one line, split it into propertyAddress, city, state, and zipCode instead of copying the whole line into propertyAddress.
Do not put city, state, or ZIP inside propertyAddress unless you truly cannot separate them.
Treat labeled variants like "Address", "Service Address", "Property Address", or "Job Address" as the property address.
If the street address appears on one line and the city/state/ZIP appears on the next line, combine both lines before splitting the address fields.
If the address is written without commas, still separate street, city, state, and ZIP when the ending state and ZIP are clear.
OCR transcript:
${rawText}`,
            },
          ],
        },
      ],
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    console.error("openai_parse_failed", payload);
    throw new Error("Lead field parsing failed at the AI provider.");
  }

  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || !content.trim()) {
    throw new Error("Lead field parsing returned an empty response.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch (error) {
    console.error("openai_parse_invalid_json", content, error);
    throw new Error("Lead field parsing returned invalid JSON.");
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("Lead field parsing returned an invalid payload.");
  }

  const draft = (parsed as { draft?: Record<string, string | boolean | null> }).draft;
  const fieldConfidences =
    (parsed as { fieldConfidences?: Array<{ fieldName?: string; confidence?: number }> }).fieldConfidences ?? [];

  if (!draft || typeof draft !== "object") {
    throw new Error("Lead field parsing did not include a draft object.");
  }

  return {
    draft,
    fieldConfidences: fieldConfidences
      .filter((item) => typeof item?.fieldName === "string" && typeof item?.confidence === "number")
      .map((item) => ({
        fieldName: item.fieldName as string,
        confidence: item.confidence as number,
      })),
  };
}

function normalizeDraft(draft: Record<string, string | boolean | null>, rawText: string) {
  const normalized = {
    homeownerFullName: normalizeString(draft.homeownerFullName),
    phoneNumber: normalizeString(draft.phoneNumber),
    email: normalizeString(draft.email),
    propertyAddress: normalizeString(draft.propertyAddress),
    city: normalizeString(draft.city),
    state: normalizeString(draft.state),
    zipCode: normalizeString(draft.zipCode),
    utilityCompany: normalizeString(draft.utilityCompany),
    notes: normalizeString(draft.notes),
    homeownerType: normalizeString(draft.homeownerType),
    averageElectricBill: normalizeString(draft.averageElectricBill),
    roofType: normalizeString(draft.roofType),
    shadingNotes: normalizeString(draft.shadingNotes),
    decisionMakerPresent: normalizeBoolean(draft.decisionMakerPresent),
    spousePresentRequired: normalizeBoolean(draft.spousePresentRequired),
    languagePreference: normalizeString(draft.languagePreference),
  };

  return normalizeAddressFields(normalized, rawText);
}

function normalizeFieldConfidences(fieldConfidences: Array<{ fieldName: string; confidence: number }>) {
  return fieldConfidences.map((item) => ({
    fieldName: item.fieldName,
    confidence: Math.max(0, Math.min(1, item.confidence)),
  }));
}

function normalizeString(value: string | boolean | null | undefined) {
  if (typeof value !== "string") return null;
  const trimmed = collapseWhitespace(value);
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeBoolean(value: string | boolean | null | undefined) {
  if (typeof value === "boolean") return value;
  return null;
}

function normalizeAddressFields(draft: {
  homeownerFullName: string | null;
  phoneNumber: string | null;
  email: string | null;
  propertyAddress: string | null;
  city: string | null;
  state: string | null;
  zipCode: string | null;
  utilityCompany: string | null;
  notes: string | null;
  homeownerType: string | null;
  averageElectricBill: string | null;
  roofType: string | null;
  shadingNotes: string | null;
  decisionMakerPresent: boolean | null;
  spousePresentRequired: boolean | null;
  languagePreference: string | null;
}, rawText: string) {
  const candidate = extractAddressCandidate(draft.propertyAddress, rawText);
  const parsedAddress = candidate ? parseAddressCandidate(candidate) : null;

  if (parsedAddress?.propertyAddress) {
    draft.propertyAddress = parsedAddress.propertyAddress;
  } else if (draft.propertyAddress) {
    draft.propertyAddress = collapseWhitespace(draft.propertyAddress);
  }

  draft.city = draft.city ?? parsedAddress?.city ?? null;
  draft.state = normalizeState(draft.state ?? parsedAddress?.state ?? null);
  draft.zipCode = draft.zipCode ?? parsedAddress?.zipCode ?? null;

  if (draft.propertyAddress && draft.city && draft.state && draft.zipCode) {
    draft.propertyAddress = stripTrailingAddressParts(draft.propertyAddress, draft.city, draft.state, draft.zipCode);
  }

  return draft;
}

function stripTrailingAddressParts(address: string, city: string, state: string, zipCode: string) {
  const escapedCity = escapeRegex(city);
  const escapedState = escapeRegex(state);
  const escapedZip = escapeRegex(zipCode);
  return address
    .replace(new RegExp(`,?\\s*${escapedCity},?\\s*${escapedState}\\s*${escapedZip}$`, "i"), "")
    .trim();
}

function escapeRegex(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function extractAddressCandidate(propertyAddress: string | null, rawText: string) {
  const transcriptLines = rawText
    .split(/\r?\n/)
    .map((line) => collapseWhitespace(line))
    .filter(Boolean);

  const labeledValue = findLabeledAddress(transcriptLines);
  if (labeledValue) {
    return labeledValue;
  }

  const transcriptValue = findAddressAroundStreetLine(transcriptLines);
  if (transcriptValue) {
    return transcriptValue;
  }

  return propertyAddress ? collapseWhitespace(propertyAddress) : null;
}

function findLabeledAddress(lines: string[]) {
  const inlineLabelPattern =
    /^(?:service|property|job|site|home)?\s*address(?:\s*(?:line)?\s*\d+)?\s*[:\-]\s*(.+)$/i;
  const labelOnlyPattern = /^(?:service|property|job|site|home)?\s*address(?:\s*(?:line)?\s*\d+)?\s*[:\-]?$/i;

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const inlineMatch = line.match(inlineLabelPattern);
    if (inlineMatch) {
      const value = inlineMatch[1]?.trim();
      const nextLine = lines[index + 1];
      if (value && nextLine && looksLikeCityStateZipLine(nextLine) && !looksLikeCityStateZipLine(value)) {
        return `${value}, ${nextLine}`;
      }
      return value ?? null;
    }

    if (labelOnlyPattern.test(line)) {
      const nextLine = lines[index + 1];
      if (!nextLine) continue;
      if (looksLikeStreetAddressLine(nextLine)) {
        const cityStateZipLine = lines[index + 2];
        if (cityStateZipLine && looksLikeCityStateZipLine(cityStateZipLine)) {
          return `${nextLine}, ${cityStateZipLine}`;
        }
        return nextLine;
      }
    }
  }

  return null;
}

function findAddressAroundStreetLine(lines: string[]) {
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (!looksLikeStreetAddressLine(line)) continue;

    const nextLine = lines[index + 1];
    if (nextLine && looksLikeCityStateZipLine(nextLine)) {
      return `${line}, ${nextLine}`;
    }

    const inlineAddress = parseAddressCandidate(line);
    if (inlineAddress?.propertyAddress && inlineAddress.city && inlineAddress.state) {
      return line;
    }
  }

  return null;
}

function parseAddressCandidate(value: string) {
  const normalized = collapseWhitespace(value)
    .replace(/\s*,\s*/g, ", ")
    .trim();
  if (!normalized) {
    return null;
  }

  const stateZipMatch = normalized.match(/^(.*?)(?:,|\s)+([A-Za-z]{2})\s+(\d{5}(?:-\d{4})?)$/);
  if (!stateZipMatch) {
    return parseStreetAndCityOnly(normalized);
  }

  const prefix = stateZipMatch[1].replace(/,\s*$/, "").trim();
  const state = stateZipMatch[2].toUpperCase();
  const zipCode = stateZipMatch[3];
  const streetCity = splitStreetAndCity(prefix);
  if (!streetCity) {
    return null;
  }

  return {
    propertyAddress: streetCity.propertyAddress,
    city: streetCity.city,
    state,
    zipCode,
  };
}

function parseStreetAndCityOnly(value: string) {
  const streetCity = splitStreetAndCity(value);
  if (!streetCity) {
    return null;
  }

  return {
    propertyAddress: streetCity.propertyAddress,
    city: streetCity.city,
    state: null,
    zipCode: null,
  };
}

function splitStreetAndCity(value: string) {
  const commaParts = value.split(",").map((part) => part.trim()).filter(Boolean);
  if (commaParts.length >= 2) {
    return {
      propertyAddress: commaParts.slice(0, -1).join(", "),
      city: commaParts[commaParts.length - 1] ?? null,
    };
  }

  const streetSuffixPattern =
    /\b(?:st|street|ave|avenue|rd|road|blvd|boulevard|dr|drive|ln|lane|ct|court|cir|circle|way|pkwy|parkway|pl|place|trl|trail|ter|terrace)\b\.?/i;
  const match = value.match(
    new RegExp(
      `^(.*?${streetSuffixPattern.source}(?:\\s+(?:apt|apartment|unit|ste|suite|#)\\s*[A-Za-z0-9-]+)?)(?:,|\\s+)([A-Za-z][A-Za-z .'-]+)$`,
      "i",
    ),
  );

  if (!match) {
    return null;
  }

  return {
    propertyAddress: match[1].trim(),
    city: match[2].trim(),
  };
}

function looksLikeStreetAddressLine(value: string) {
  return /^\d+[A-Za-z0-9\-\/]*\s+.+\b(?:st|street|ave|avenue|rd|road|blvd|boulevard|dr|drive|ln|lane|ct|court|cir|circle|way|pkwy|parkway|pl|place|trl|trail|ter|terrace)\b\.?/i.test(
    value,
  );
}

function looksLikeCityStateZipLine(value: string) {
  return /^[A-Za-z][A-Za-z .'-]+,\s*[A-Za-z]{2}\s+\d{5}(?:-\d{4})?$/i.test(value)
    || /^[A-Za-z][A-Za-z .'-]+\s+[A-Za-z]{2}\s+\d{5}(?:-\d{4})?$/i.test(value);
}

function normalizeState(value: string | null) {
  if (!value) return null;
  const trimmed = collapseWhitespace(value);
  return trimmed.length === 2 ? trimmed.toUpperCase() : trimmed;
}

function collapseWhitespace(value: string) {
  return value.replace(/\s+/g, " ").trim();
}

function respond(status: number, payload: Record<string, string>) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: jsonHeaders,
  });
}

function encodeBase64(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

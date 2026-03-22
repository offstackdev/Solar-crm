import Foundation

protocol LeadServicing {
    func fetchLeads() async -> [Lead]
    func fetchLead(id: UUID) async -> Lead?
    func saveLead(_ lead: Lead) async -> Lead
    func updateLead(_ lead: Lead) async -> Lead
}

actor MockLeadService: LeadServicing {
    private var leads: [Lead]

    init(leads: [Lead]) {
        self.leads = leads
    }

    func fetchLeads() async -> [Lead] {
        leads.sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchLead(id: UUID) async -> Lead? {
        leads.first(where: { $0.id == id })
    }

    func saveLead(_ lead: Lead) async -> Lead {
        leads.insert(lead, at: 0)
        return lead
    }

    func updateLead(_ lead: Lead) async -> Lead {
        guard let index = leads.firstIndex(where: { $0.id == lead.id }) else {
            leads.insert(lead, at: 0)
            return lead
        }
        leads[index] = lead
        return lead
    }
}

import SwiftUI

/// Tab displaying synced contacts with search and dial functionality.
struct ContactsListView: View {
    
    @StateObject var viewModel: ContactsListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Contacts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: viewModel.requestSync) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .rotationEffect(.degrees(viewModel.isSyncing ? 360 : 0))
                        .animation(viewModel.isSyncing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isSyncing)
                }
                .buttonStyle(.plain)
                .foregroundColor(.dialwaveSecondary)
                .help("Sync contacts from phone")
            }
            .padding()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.dialwaveSecondary)
                
                TextField("Search names or numbers", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.dialwaveSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.dialwaveSecondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // List
            if viewModel.contacts.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.largeTitle)
                        .foregroundColor(.dialwaveSecondary)
                    Text(viewModel.searchQuery.isEmpty ? "No contacts found" : "No results for '\(viewModel.searchQuery)'")
                        .foregroundColor(.dialwaveSecondary)
                    
                    if viewModel.searchQuery.isEmpty {
                        CustomButton(title: "Sync Contacts", icon: "arrow.triangle.2.circlepath", style: .outline) {
                            viewModel.requestSync()
                        }
                        .frame(width: 140)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            } else {
                List(viewModel.contacts) { contact in
                    ContactRow(contact: contact) {
                        viewModel.dial(contact: contact)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            viewModel.refreshContacts()
        }
    }
}

private struct ContactRow: View {
    let contact: Contact
    let onDial: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dialwavePrimary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Text(contact.initials)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dialwavePrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .fontWeight(.medium)
                
                if let primaryNumber = contact.primaryNumber {
                    Text(primaryNumber.formatPhoneNumber())
                        .font(.caption)
                        .foregroundColor(.dialwaveSecondary)
                }
            }
            
            Spacer()
            
            // Call Button (appears on hover)
            if isHovering {
                Button(action: onDial) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.dialwaveGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovering ? Color.dialwaveSecondary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

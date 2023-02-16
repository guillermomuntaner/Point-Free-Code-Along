//
//  StandupsList.swift
//  Standups
//
//  Created by Guillermo Muntaner on 13.02.23.
//

import SwiftUINavigation
import SwiftUI
import IdentifiedCollections
import Combine

final class StandupsListModel: ObservableObject {
    @Published var destination: Destination? {
        didSet { self.bind() }
    }
    @Published var standups: IdentifiedArrayOf<Standup>

    private var destinationCancellable: AnyCancellable?

    enum Destination {
        case add(EditStandupModel)
        case detail(StandupDetailModel)
    }

    init(
        destination: Destination? = nil,
        standups: IdentifiedArrayOf<Standup> = []
    ) {
        self.destination = destination
        self.standups = standups
        self.bind()
    }

    func addStandupButtonTapped() {
        self.destination = .add(EditStandupModel(standup: Standup(id: Standup.ID(UUID()))))
    }

    func dismissAddStandupButtonTap() {
        self.destination = nil
    }

    func confirmAddStandupButtonTapped() {
        defer { self.destination = nil }

        guard case let .add(editStandupModel) = self.destination
        else { return }

        var standup = editStandupModel.standup

        standup.attendees.removeAll { attendee in
            attendee.name.allSatisfy(\.isWhitespace)
        }
        if standup.attendees.isEmpty {
            standup.attendees.append(Attendee(id: Attendee.ID(UUID()), name: ""))
        }
        self.standups.append(standup)
    }

    func standupTapped(standup: Standup) {
        self.destination = .detail(
            StandupDetailModel(standup: standup)
        )
    }

    private func bind() {
        switch self.destination {
        case let .detail(standupDetailModel):
            standupDetailModel.onConfirmDeletion = { [weak self, id = standupDetailModel.standup.id] in
                guard let self else { return }

                withAnimation {
                    self.standups.remove(id: id)
                    self.destination = nil
                }
            }

            self.destinationCancellable = standupDetailModel.$standup
                .sink { [weak self] standup in
                    guard let self else { return }

                    self.standups[id: standup.id] = standup
                }

        case .add, .none:
            break
        }
    }
}

struct StandupsList: View {
    @ObservedObject var model: StandupsListModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.model.standups) { standup in
                    Button {
                        self.model.standupTapped(standup: standup)
                    } label: {
                        CardView(standup: standup)
                    }
                    .listRowBackground(standup.theme.mainColor)
                }
            }
            .toolbar {
                Button {
                    self.model.addStandupButtonTapped()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Daily Standups")
            .sheet(
                unwrapping: self.$model.destination,
                case: /StandupsListModel.Destination.add // CasePath is a PointFree.co lib
            ) { $model in
                NavigationStack {
                    EditStandupView(model: model)
                        .navigationTitle("New standup")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    self.model.dismissAddStandupButtonTap()
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    self.model.confirmAddStandupButtonTapped()
                                }
                            }
                        }
                }
            }
            .navigationDestination(
                unwrapping: self.$model.destination,
                case: /StandupsListModel.Destination.detail
            ) { $detailModel in
                StandupDetailView(model: detailModel)
            }
        }
    }
}

struct CardView: View {
    let standup: Standup

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.standup.title)
                .font(.headline)
            Spacer()
            HStack {
                Label(
                    "\(self.standup.attendees.count)",
                    systemImage: "person.3"
                )
                Spacer()
                Label(
                    self.standup.duration.formatted(.units()),
                    systemImage: "clock"
                )
                .labelStyle(.trailingIcon)
            }
            .font(.caption)
        }
        .padding()
        .foregroundColor(self.standup.theme.accentColor)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: Self { Self() }
}

struct StandupsList_Previews: PreviewProvider {
    static var previews: some View {
        StandupsList(model: StandupsListModel(
            standups: [
                .mock,
            ]
        ))
    }
}

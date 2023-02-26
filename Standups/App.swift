//
//  App.swift
//  Standups
//
//  Created by Guillermo Muntaner on 26.02.23.
//

import Dependencies
import SwiftUI
import Combine

@MainActor
class AppModel: ObservableObject {
    @Published var path: [Destination] {
        didSet { self.bind() }
    }
    @Published var standupList: StandupsListModel {
        didSet { self.bind() }
    }

    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    private var detailCancellable: AnyCancellable?

    enum Destination: Hashable {
        case detail(StandupDetailModel)
        case meeting(Meeting, standup: Standup)
        case record(RecordMeetingModel)
    }

    init(
        path: [Destination] = [],
        standupList: StandupsListModel
    ) {
        self.path = path
        self.standupList = standupList
        self.bind()
    }

    private func bind() {
        self.standupList.onStandupTapped = { [weak self] standup in
            guard let self else { return }

            self.path.append(
                .detail(
                    StandupDetailModel(standup: standup)
                )
            )
        }

        for destination in self.path {
            switch destination {
            case let .detail(detailModel):
                detailModel.onMeetingStarted = { [weak self] standup in
                    guard let self else { return }

                    self.path.append(
                        .record(
                            RecordMeetingModel(standup: standup)
                        )
                    )
                }
                detailModel.onConfirmDeletion = { [weak self, weak detailModel] in
                    guard let self, let detailModel else { return }

                    self.standupList.standups.remove(id: detailModel.standup.id)
                    _ = self.path.popLast()
                }
                detailModel.onMeetingTapped = { [weak self, weak detailModel] meeting in
                    guard let self, let detailModel else { return }

                    self.path.append(
                        .meeting(meeting, standup: detailModel.standup)
                    )
                }

                self.detailCancellable = detailModel.$standup.sink { [weak self] standup in
                    self?.standupList.standups[id: standup.id] = standup
                }

            case .meeting:
                break

            case let .record(recordModel):
                recordModel.onDiscardMeeting = { [weak self] in
                    guard let self else { return }
                    _ = self.path.popLast()
                }
                recordModel.onMeetingFinished = { [weak self] transcript in
                    guard let self else { return }

                    let meeting = Meeting(
                        id: Meeting.ID(self.uuid()),
                        date: self.now,
                        transcript: transcript
                    )

                    guard case let .some(.detail(detailModel)) = self.path.dropLast().last
                    else {
                        return
                    }

                    detailModel.standup.meetings.insert(meeting, at: 0)
                    _ = self.path.popLast()

                }
            }
        }
    }
}

struct AppView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack(path: self.$model.path) {
            StandupsList(model: self.model.standupList)
                .navigationDestination(for: AppModel.Destination.self) { destination in
                    switch destination {
                    case let .detail(detailModel):
                        StandupDetailView(model: detailModel)
                    case let .meeting(meeting, standup: standup):
                        MeetingView(meeting: meeting, standup: standup)
                    case let .record(recordModel):
                        RecordMeetingView(model: recordModel)
                    }
                }
        }
    }
}

//
//  StandupDetail.swift
//  Standups
//
//  Created by Guillermo Muntaner on 15.02.23.
//

import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay
import Clocks
import Dependencies

@MainActor
class StandupDetailModel: ObservableObject {
    @Published var destination: Destination? {
        didSet { self.bind() }
    }
    @Published var standup: Standup
    
    @Dependency(\.continuousClock) var clock
    
    var onConfirmDeletion: () -> Void = unimplemented("StandupDetailModel.onConfirmDeletion")
    
    enum Destination {
        case alert(AlertState<AlertAction>)
        case edit(EditStandupModel )
        case meeting(Meeting)
        case record(RecordMeetingModel)
    }
    
    enum AlertAction {
        case confirmDelition
    }
    
    init(
        destination: Destination? = nil,
        standup: Standup
    ) {
        self.destination = destination
        self.standup = standup
        self.bind()
    }
    
    func deleteMeetings(atOffsets indices: IndexSet) {
        self.standup.meetings.remove(atOffsets: indices)
    }
    
    func meetingTapping(_ meeting: Meeting) {
        self.destination = .meeting(meeting)
    }
    
    func deleteButtonTapped() {
        self.destination = .alert(AlertState.delete)
    }
    
    func alertButtonTapped(_ action: AlertAction) {
        switch action {
        case .confirmDelition:
            self.onConfirmDeletion()
        }
    }
    
    func editButtonTapped() {
        self.destination = .edit(EditStandupModel(standup: self.standup ))
    }
    
    func cancelEditButtonTapped() {
        self.destination = nil
    }
    
    func doneEditingButtonTapped() {
        guard case let .edit(model) = self.destination
        else { return }
        
        self.standup = model.standup
        self.destination = nil 
    }
    
    func startMeetingTapped() {
        self.destination = .record(RecordMeetingModel(standup: standup))
    }
    
    private func bind() {
        switch destination {
        case let .record(recordMeetingModel):
            recordMeetingModel.onMeetingFinished = { [weak self] transcript in
                guard let self else { return }
                
                Task {
                    try? await self.clock.sleep(for: .milliseconds(400))
                    withAnimation {
                        _ = self.standup.meetings.insert(
                            Meeting(
                                id: Meeting.ID(UUID()),
                                date: Date(),
                                transcript: transcript
                            ),
                            at: 0
                        )
                    }
                }
                self.destination = nil
            }
            
        case .edit, .alert, .meeting, .none:
            break
        }
    }
}

extension AlertState where Action == StandupDetailModel.AlertAction {
    static let delete = AlertState(
        title: TextState("Delete?"),
        message: TextState("Are you sure you want to delete this meeting?"),
        buttons: [
            .destructive(TextState("Yes"), action: .send(.confirmDelition)),
            .cancel(TextState("Nevermind"))
        ]
    )
}

struct StandupDetailView: View {
    @ObservedObject var model: StandupDetailModel
    
    var body: some View {
        List {
            Section {
                Button {
                    self.model.startMeetingTapped()
                } label: {
                    Label("Start Meeting", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Label("Length", systemImage: "clock")
                    Spacer()
                    Text(self.model.standup.duration.formatted(
                        .units())
                    )
                }
                
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text(self.model.standup.theme.name)
                        .padding(4)
                        .foregroundColor(
                            self.model.standup.theme.accentColor
                        )
                        .background(self.model.standup.theme.mainColor)
                        .cornerRadius(4)
                }
            } header: {
                Text("Standup Info")
            }
            
            if !self.model.standup.meetings.isEmpty {
                Section {
                    ForEach(self.model.standup.meetings) { meeting in
                        Button {
                            self.model.meetingTapping(meeting)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(meeting.date, style: .date)
                                Text(meeting.date, style: .time)
                            }
                        }
                    }
                    .onDelete { indices in
                        self.model.deleteMeetings(atOffsets: indices)
                    }
                } header: {
                    Text("Past meetings")
                }
            }
            
            Section {
                ForEach(self.model.standup.attendees) { attendee in
                    Label(attendee.name, systemImage: "person")
                }
            } header: {
                Text("Attendees")
            }
            
            Section {
                Button("Delete") {
                    self.model.deleteButtonTapped()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(self.model.standup.title)
        .toolbar {
            Button("Edit") {
                self.model.editButtonTapped()
            }
        }
        .navigationDestination(
            unwrapping: self.$model.destination,
            case: /StandupDetailModel.Destination.meeting
        ) { $meeting in
            MeetingView(meeting: meeting, standup: self.model.standup)
        }
        .alert(
            unwrapping: self.$model.destination,
            case: /StandupDetailModel.Destination.alert
        ) { action in
            self.model.alertButtonTapped(action)
        }
        .sheet(
            unwrapping: self.$model.destination,
            case: /StandupDetailModel.Destination.edit
        ) { $editModel in
            NavigationStack {
                EditStandupView(model: editModel)
                    .navigationTitle(self.model.standup.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                self.model.cancelEditButtonTapped()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                self.model.doneEditingButtonTapped()
                            }
                        }
                    }
            }
        }
        .navigationDestination(
            unwrapping: self.$model.destination,
            case: /StandupDetailModel.Destination.record
        ) { $recordMeetingModel in
            RecordMeetingView(model: recordMeetingModel)
        }
    }
}

struct MeetingView: View {
    let meeting: Meeting
    let standup: Standup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Divider()
                    .padding(.bottom)
                Text("Attendees")
                    .font(.headline)
                ForEach(self.standup.attendees) { attendee in
                    Text(attendee.name)
                }
                Text("Transcript")
                    .font(.headline)
                    .padding(.top)
                Text(self.meeting.transcript)
            }
        }
        .navigationTitle(
            Text(self.meeting.date, style: .date)
        )
        .padding()
    }
}

struct StandupDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StandupDetailView(
                model: StandupDetailModel(standup: .mock)
            )
        }
    }
}

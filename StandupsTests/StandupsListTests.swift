//
//  StandupsListTests.swift
//  StandupsTests
//
//  Created by Guillermo Muntaner on 16.02.23.
//

import XCTest
import Dependencies
import CustomDump

@testable import Standups

@MainActor
class StandupsListTests: XCTestCase {
    func testPersistence() async throws {
        let mainQueue = DispatchQueue.test
        withDependencies {
            $0.dataManager = .fake()
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        } operation: {
            let listModel = StandupsListModel()

            XCTAssertEqual(listModel.standups.count, 0)
            listModel.addStandupButtonTapped()
            listModel.confirmAddStandupButtonTapped()
            XCTAssertEqual(listModel.standups.count, 1)

            mainQueue.run()

            let nextLaunchListModel = StandupsListModel()
            XCTAssertEqual(
                nextLaunchListModel.standups.count, 1
            )
        }
    }

    func testEdit() throws {
        let mainQueue = DispatchQueue.test
        try withDependencies {
            $0.dataManager = .fake(
                initialData: try JSONEncoder().encode([Standup.mock])
            )
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        } operation: {
            let listModel = StandupsListModel()
            XCTAssertEqual(listModel.standups.count, 1)

            listModel.standupTapped(standup: listModel.standups[0])
            guard
              case let .some(.detail(detailModel))
                = listModel.destination
            else {
              XCTFail()
              return
            }
            XCTAssertNoDifference(
              detailModel.standup, listModel.standups[0]
            )

            detailModel.editButtonTapped()
            guard case let .some(.edit(editModel)) = detailModel.destination else {
                XCTFail()
                return
            }
            XCTAssertEqual(editModel.standup, detailModel.standup)

            editModel.standup.title = "Product"
            detailModel.doneEditingButtonTapped()

            XCTAssertNil(detailModel.destination)
            XCTAssertEqual(detailModel.standup.title, "Product")

            listModel.destination = nil

            XCTAssertEqual(listModel.standups[0].title, "Product")
        }
    }
}

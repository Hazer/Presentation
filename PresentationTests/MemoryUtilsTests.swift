//
//  MomoryUtilsTests.swift
//  iZettlePresentationTests
//
//  Created by Emmanuel Garnier on 2017-10-02.
//  Copyright © 2017 iZettle. All rights reserved.
//

import XCTest
import Flow
@testable import Presentation

private final class Foo: NSObject {
    var foo: Foo? // To create retain cycle

    init(withRetainCycle: Bool = false) {
        super.init()
        foo = withRetainCycle ? self: nil
    }
}

class MemoryUtilsTests: XCTestCase {
    func testDeallocSignal() {
        var object: Foo? = Foo()

        let bag = DisposeBag()

        let expectation = self.expectation(description: "object deallocated")

        bag += object?.deallocSignal.onValue { _ in
            expectation.fulfill()
        }

        object = nil

        waitForExpectations(timeout: 10) { _ in
            bag.dispose()
        }
    }

    func testNSObjectDeallocSignal() {
        var object: UILabel? = UILabel()

        let bag = DisposeBag()
        let expectation = self.expectation(description: "object deallocated")

        bag += object?.deallocSignal.onValue { _ in
            expectation.fulfill()
        }

        Scheduler.main.async(after: 2) {
            object = nil
        }

        waitForExpectations(timeout: 10) { _ in
            bag.dispose()
        }
    }

    func testTrackLeaks() {
        let bag = DisposeBag()

        let expectation = self.expectation(description: "object deallocated")

        autoreleasepool {
            let object = Foo(withRetainCycle: true)
            bag.hold(object)
            object.trackMemoryLeak(whenDisposed: bag) { _ in
                expectation.fulfill()
            }
        }

        bag.dispose()

        waitForExpectations(timeout: 10) { _ in

        }
    }

    func testTrackLeaksNotFired() {
        let bag = DisposeBag()

        autoreleasepool {
            let object = Foo(withRetainCycle: false)
            bag.hold(object)
            object.trackMemoryLeak(whenDisposed: bag) { _ in
                XCTFail("Object should not leak")
            }
        }

        bag.dispose()

        let expectation = self.expectation(description: "object got deallocated")
        Scheduler.main.async(after: 2) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10) { _ in

        }
    }

    func testWeak() {
        var elements: [Foo]? = [Foo(), Foo(), Foo()]

        let weakArray = elements!.map { Weak($0) }

        XCTAssertEqual(weakArray.compactMap({ $0.value }), elements!)

        elements = nil

        XCTAssertEqual(weakArray.compactMap({ $0.value }), [])
    }
}

import Foundation
import XCTest
@testable import Verba

final class SM2EngineTests: XCTestCase {
    var service = SM2Service()

    func testInitialRatingSetsFirstRepetition() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 4)

        XCTAssertEqual(word.repetitions, 1)
        XCTAssertEqual(word.interval, 1)
        XCTAssertGreaterThan(word.lastReviewed ?? .distantPast, Date().addingTimeInterval(-10))
        XCTAssertEqual(word.difficultyRating, 4)
    }

    func testSecondCorrectRatingSetsSixDayInterval() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 5)
        service.rate(word, quality: 5)

        XCTAssertEqual(word.repetitions, 2)
        XCTAssertEqual(word.interval, 6)
    }

    func testThirdCorrectRatingUsesEaseFactorMultiplier() {
        let word = Word(polish: "test", english: "test")
        word.easeFactor = 2.0

        service.rate(word, quality: 5)
        service.rate(word, quality: 5)
        service.rate(word, quality: 5)

        XCTAssertEqual(word.repetitions, 3)
        XCTAssertEqual(word.interval, 13)
    }

    func testQualityBelowThreeResetsRepetitionsAndInterval() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 5)
        XCTAssertEqual(word.repetitions, 1)

        service.rate(word, quality: 2)

        XCTAssertEqual(word.repetitions, 0)
        XCTAssertEqual(word.interval, 1)
    }

    func testEaseFactorNeverDropsBelowMinimum() {
        let word = Word(polish: "test", english: "test")

        for _ in 0..<20 {
            service.rate(word, quality: 0)
        }

        XCTAssertGreaterThanOrEqual(word.easeFactor, 1.3)
    }

    func testMasteryThresholdAfterFiveSuccessfulRepetitions() {
        let word = Word(polish: "test", english: "test")

        XCTAssertFalse(word.isMastered)
        for _ in 1...5 {
            service.rate(word, quality: 4)
        }

        XCTAssertTrue(word.isMastered)
    }

    func testNextReviewAdvancesAtLeastOneDay() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 4)

        XCTAssertGreaterThan(word.nextReview, Date())
    }

    func testQualityHigherThanFiveIsClamped() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 100)

        XCTAssertEqual(word.difficultyRating, 5)
    }

    func testQualityLowerThanZeroIsClamped() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: -4)

        XCTAssertEqual(word.difficultyRating, 0)
    }
}

final class AnswerNormalizerTests: XCTestCase {
    private let sut = AnswerNormalizer()

    func testNormalizeRemovesDiacriticsAndCollapsesWhitespace() {
        let normalized = sut.normalize("  Żółć   ma\tkota  ")

        XCTAssertEqual(normalized, "zolc ma kota")
    }

    func testVariantsSplitsBySeparatorsAndIncludesWholeValue() {
        let variants = sut.variants(for: "house/home, dwelling")

        XCTAssertTrue(variants.contains("house"))
        XCTAssertTrue(variants.contains("home"))
        XCTAssertTrue(variants.contains("dwelling"))
        XCTAssertTrue(variants.contains("house/home, dwelling"))
    }
}

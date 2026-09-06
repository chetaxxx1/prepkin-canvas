import XCTest
@testable import PrepkinCanvas

/// The guess rule, driven through the real game model rather than the keyboard, so
/// the "no, and it costs you nothing" path is checked on every run.
@MainActor
final class WordleGuessTests: XCTestCase {
    private func game(typing word: String) -> WordleGame {
        let g = WordleGame()
        for letter in word.map(String.init) { g.key(letter) }
        return g
    }

    /// Five letters that aren't a word: the row shakes, the letters stay put, and the
    /// student still has all six tries.
    func testANonWordIsRefusedAndCostsNoTry() {
        let g = game(typing: "FINET")
        let shakeBefore = g.shake

        XCTAssertEqual(g.submit(onWin: { _ in }), .notAWord)
        XCTAssertNotEqual(g.shake, shakeBefore, "the row did not shake")
        XCTAssertTrue(g.guesses.isEmpty, "a non-word was scored onto the board")
        XCTAssertEqual(g.triesLeft, 6, "a non-word ate a try")
        XCTAssertEqual(g.current, "FINET", "the letters were cleared off the row")
        XCTAssertFalse(g.finished)
    }

    /// A real word goes on the board and costs one of the six.
    func testARealWordScores() {
        let g = game(typing: "CRANE")

        XCTAssertEqual(g.submit(onWin: { _ in }), .accepted)
        XCTAssertEqual(g.guesses, ["CRANE"])
        XCTAssertEqual(g.triesLeft, 5)
        XCTAssertEqual(g.current, "")
        XCTAssertEqual(g.states(for: "CRANE").count, 5)
    }

    /// The guess list is much wider than the answer list, so a word we'd never make
    /// the puzzle out of is still a legal thing to spend a try on.
    func testAWordThatIsNeverAnAnswerIsStillALegalGuess() {
        let extras = Catalog.wordleGuesses.subtracting(Catalog.wordleAnswers)
        let word = try? XCTUnwrap(extras.sorted().first)
        let g = game(typing: word ?? "")

        XCTAssertGreaterThan(extras.count, 1_000, "the guess list is barely wider than the answers")
        XCTAssertEqual(g.submit(onWin: { _ in }), .accepted)
    }

    /// Short of five letters is still just a shake — unchanged behaviour.
    func testAShortGuessIsStillRefused() {
        let g = game(typing: "FINE")
        let shakeBefore = g.shake

        XCTAssertEqual(g.submit(onWin: { _ in }), .tooShort)
        XCTAssertNotEqual(g.shake, shakeBefore)
        XCTAssertTrue(g.guesses.isEmpty)
    }

    /// The day's own word has to be submittable, whatever the lists say.
    func testTodaysAnswerIsAcceptedAsAGuess() {
        let g = game(typing: WordleGame.answer())

        XCTAssertEqual(g.submit(onWin: { _ in }), .accepted)
        XCTAssertTrue(g.won)
    }
}

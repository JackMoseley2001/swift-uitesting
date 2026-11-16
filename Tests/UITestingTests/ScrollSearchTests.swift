import Testing

@testable import UITesting

@Suite
struct ScrollSearchTests {
    /// Content of a fixed length, of which one position is in view at a time.
    private final class Content {
        let length: Int
        let target: Int?
        var position: Int
        var swipes: [ScrollDirection] = []

        init(length: Int, position: Int, target: Int?) {
            self.length = length
            self.position = position
            self.target = target
        }

        func find(_ direction: ScrollDirection = .down, maximumSwipes: Int = 20) -> Bool {
            ScrollSearch.find(
                direction: direction,
                maximumSwipes: maximumSwipes,
                isInView: { self.position == self.target },
                scroll: { direction in
                    self.swipes.append(direction)
                    let next = min(max(self.position + (direction == .down ? 1 : -1), 0), self.length - 1)
                    defer { self.position = next }
                    return next != self.position
                }
            )
        }
    }

    @Test
    func doesNotScrollWhenTheElementIsInView() {
        let content = Content(length: 10, position: 3, target: 3)

        #Testing::expect(content.find())
        #Testing::expect(content.swipes.isEmpty)
    }

    @Test
    func scrollsUntilTheElementIsInView() {
        let content = Content(length: 10, position: 0, target: 4)

        #Testing::expect(content.find())
        #Testing::expect(content.swipes == Array(repeating: .down, count: 4))
    }

    @Test
    func goesBackTheOtherWayAtTheEnd() {
        let content = Content(length: 5, position: 3, target: 1)

        #Testing::expect(content.find())
        #Testing::expect(content.swipes == [.down, .down, .up, .up, .up])
    }

    @Test
    func goesBackTheOtherWayAtTheLimit() {
        let content = Content(length: 100, position: 50, target: 48)

        #Testing::expect(content.find(maximumSwipes: 2))
        #Testing::expect(content.swipes == [.down, .down, .up, .up, .up, .up])
    }

    @Test
    func failsWhenTheElementIsNowhere() {
        let content = Content(length: 4, position: 0, target: nil)

        #Testing::expect(!content.find())
        #Testing::expect(content.swipes == [.down, .down, .down, .down, .up, .up, .up, .up])
    }

    @Test
    func failsWhenTheElementIsBeyondTheLimit() {
        let content = Content(length: 100, position: 0, target: 90)

        #Testing::expect(!content.find(maximumSwipes: 3))
        #Testing::expect(content.swipes.count == 3 + 4)
    }

    @Test
    func oppositeDirections() {
        #Testing::expect(ScrollDirection.up.opposite == .down)
        #Testing::expect(ScrollDirection.down.opposite == .up)
        #Testing::expect(ScrollDirection.left.opposite == .right)
        #Testing::expect(ScrollDirection.right.opposite == .left)
    }
}

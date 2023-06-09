import ComposableArchitecture
import BookFinder
import StateManager
import Models

public struct ScannerViewState: ReducerProtocol {
    public struct State: Equatable {
        var isTorchOn: Bool = false
        var feedbackPopUp: ScannerFeedbackPopUp.State? = nil
    }
    public enum Action: Equatable {
        case closeTapped
        case toggleTorch
        case scannerSuccess(String)
        case bookAlreadyInShelf
        case bookFound(Book)
        case bookNotFound
        case scannerFailure
        case closePopUp
        case addBook(Book)
        case feedbackPopUp(ScannerFeedbackPopUp.Action)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.booksState) var booksState

    enum CancelID { case closeAction }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            struct CloseAction: Hashable {}
            switch action {
            case .toggleTorch:
                state.isTorchOn.toggle()
                return .none
            case .scannerSuccess(let isbn):
                state.isTorchOn = false
                guard state.feedbackPopUp == nil else { return .none }
                state.feedbackPopUp = .loading(ISBN: isbn)
                return .run(priority: .high) { send in
                    if await booksState.loadBooks().contains(where: { $0.compareISBN(isbn) }) {
                        await send(.bookAlreadyInShelf)
                    } else {
                        do {
                            await send(.bookFound(try await BookFinder.search(isbn: isbn)))
                        } catch {
                            await send(.bookNotFound)
                        }
                    }
                }.cancellable(id: CancelID.closeAction)
            case .bookAlreadyInShelf:
                state.feedbackPopUp = .bookAlreadyExisting
                return .none
            case .bookFound(let book):
                state.feedbackPopUp = .newBook(book)
                return .none
            case .bookNotFound:
                state.feedbackPopUp = .bookNotFound
                return .run { send in
                    try await self.clock.sleep(for: .seconds(5))
                    await send(.closePopUp, animation: .easeInOut)
                }.cancellable(id: CancelID.closeAction)
            case .scannerFailure:
                state.feedbackPopUp = .failure
                return .run { send in
                    try await self.clock.sleep(for: .seconds(3))
                    await send(.closePopUp, animation: .easeInOut)
                }.cancellable(id: CancelID.closeAction)
            case .feedbackPopUp(.cancelButtonTapped), .closePopUp:
                state.feedbackPopUp = nil
                return .cancel(id: CancelID.closeAction)
            case .feedbackPopUp(.addBookTapped):
                if case let .newBook(book) = state.feedbackPopUp {
                    return .send(.addBook(book))
                }
                return .none
            case .closeTapped:
                state.isTorchOn = false
                return .none
            case .addBook:
                return .none
            }
        }
        .ifLet(\.feedbackPopUp, action: /Action.feedbackPopUp) {
            ScannerFeedbackPopUp()
        }
    }
}

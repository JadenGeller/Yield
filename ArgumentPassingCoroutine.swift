import Dispatch

private let coroutineQueue = dispatch_queue_create("argument-passing-coroutine", DISPATCH_QUEUE_CONCURRENT)

private enum TransportStorage<Argument, Element> {
    case Input(Argument)
    case Output(Element)
}

public class ArgumentPassingCoroutine<Argument, Element> {
    private let callerReady = dispatch_semaphore_create(0)
    private let coroutineReady = dispatch_semaphore_create(0)
    private var done: Bool = false
    private var transportStorage: TransportStorage<Argument, Element>?
    
    public typealias Yield = Element -> Argument
    public init(implementation: Yield -> ()) {
        dispatch_async(coroutineQueue) {
            // Don't start coroutine until first call.
            dispatch_semaphore_wait(self.callerReady, DISPATCH_TIME_FOREVER)
            
            implementation { next in
                // Place element in transport storage, and let caller know it's ready.
                self.transportStorage = .Output(next)
                dispatch_semaphore_signal(self.coroutineReady)
                
                // Don't continue coroutine until next call.
                dispatch_semaphore_wait(self.callerReady, DISPATCH_TIME_FOREVER)
                
                // Caller sent the next argument, so let's continue.
                defer { self.transportStorage = nil }
                guard case let .Some(.Input(input)) = self.transportStorage else { fatalError() }
                return input
            }
            
            // The coroutine is forever over, so let's let the caller know.
            self.done = true
            dispatch_semaphore_signal(self.coroutineReady)
        }
    }
    
    public func next(argument: Argument) -> Element? {
        // Make sure work is happening before we wait.
        guard !done else { return nil }
        
        // Return to the coroutine, passing the argument.
        transportStorage = .Input(argument)
        dispatch_semaphore_signal(callerReady)
								
        // Wait until it has finished.
        dispatch_semaphore_wait(coroutineReady, DISPATCH_TIME_FOREVER)
        
        // Return to the caller the result, then clear it.
        defer { transportStorage = nil }
        guard case let .Some(.Output(output)) = transportStorage else { return nil }
        return output
    }
}

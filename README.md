# Yield

Lots of languages allow uses to `yield` in functions to easily create generators and coroutines. Yield brings this functionality to Swift using threads. Essentially, Yield spawns a new thread for each coroutine and pauses it when waiting for the next call to `next`.

```swift
let maxFibbValue = 100

let fibbGenerator = Coroutine<Int> { yield in
    var (a, b) = (1, 1)
    while b < maxValue {
        (a, b) = (b, a + b)
        yield(a)
   }
}
```

The above coroutine will, on first call to `next`, begin execution. Once it reaches the first `yield` call, it will stop, and wait until the next call to `next`. This will continue until the coroutine finishes execution and returns. At this point, `next` will return `nil`.

Note that a `Coroutine` is a `GeneratorType`, so we can wrap it in an `AnySequence` and use it multiple times.
```swift
let fibb = AnySequence { fibbGenerator }

for x in fibb {
    print(x) // -> 1, 2, 3, 5, 8, 13, 21, 55, 89
}
```

## Usage

If you want to use `Coroutine` in a iOS or OS X, it's super easy---just use it! If you want to use it in a Playground or a command line application, however, its a bit tricker (but not hard!). Since these don't have main run loop (and thus will never check the coroutine thread to see if its ready), our coroutines won't work. There's an easy fix though. Write all your code in `func main() { ... }`, and then put the following after your function declaration:
```swift
dispatch_async(dispatch_get_main_queue(), main)
dispatch_async(dispatch_get_main_queue(), { exit(0) })
dispatch_main()
```
This will make sure your main function runs and that the program exits once it returns. Additionally, this will start the programs run loop so that our coroutine thread will run.

## One more thing...

If you wanna be a coroutine master, check out `ArgumentPassingCoroutine`. This class gives up its sibling's `GeneratorType` conformance for an even cooler power---the ability to send data back into the coroutine when `next` is called! Check it out!
```swift
let accumulator = ArgumentPassingCoroutine<Int, Int> { yield in
	var total = 0
	while true {
		total += yield(total)
	}
}

for i in 0...10 {
	print(accumulator.next(i)) // -> 0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55
}
```

What're these useful for? Well, [concurrency](http://www.dabeaz.com/coroutines/) and [combinatorics](http://sahandsaba.com/combinatorial-generation-using-coroutines-in-python.html) and [asynchronous IO](http://sahandsaba.com/understanding-asyncio-node-js-python-3-4.html) and lots more!

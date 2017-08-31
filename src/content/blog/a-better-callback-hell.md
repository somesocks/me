---
title: "A Better Callback Hell"
date: 2017-08-31T21:23:22+02:00
---

In my day-to-day work, I write quite a lot of JavaScript.  And, you really can't get far in JS before you have to write asynchronous code.

Thanks to first-class functions and closures, handling asynchronous code with callbacks is pretty easy in JS, compared to C++ or Java.

That said, it can get easy to write some sort of unreadable mess, especially when you have to chain asynchronous dependencies.  We're all pretty familiar with 'callback hell', where you nest callbacks inside callbacks ad nauseam:

```JavaScript
function doSomething (value, callback) {
  function onSomething1 (err, res) {
    function onSomething2 (err, res) {
      function onSomething3 (err, res) {
        if (err) {
          callback(err);
        } else {
          doSomething4(res, callback);
        }
      }
      if (err) {
        onSomething3(err);
      } else {
        doSomething3(res, onSomething3);
      }
    }
    if (err) {
      onSomething2(err);
    } else {
      doSomething2(res, onSomething2);
    }
  }
  doSomething1(value, onSomething1);
}
```

How do we fix this?  The recommended solution today is Promises (and async/await).  A Promise is an asynchronous abstraction, representing some code that has yet to be evaluated.
Promises do two things to address ugliness in the above code: \

--they automatically handle error propogation \
--they allow dependency chaining. \

```JavaScript
  var promise = new Promise()
    .then(doSomething1)
    .then(doSomething2)
    .then(doSomething3)
    .then(doSomething4);
```

Looks much cleaner, right?  So, why don't I like Promises?


## Eager Evaluation

So, if a Promise represents a deferred asynchronous operation, when does it actually execute?  Turns out, a Promise actually starts operation synchronously as soon as you construct it.

```Javaascript
console.log('A');

new Promise(
    (resolve, reject) => { console.log('B'); resolve(); }
  )
  .then(() => console.log('C'));

console.log('D');

// prints out A B D C
```

Its convenient that you don't have to start execution yourself, but it also can cause some headaches,
and often you have to write Promise generators to handle dependency chains correctly.

```Javaascript
new Promise(doSomething1)
  .then((res) => new Promise(doSomething2)) // promise generator
  .then((res) => new Promise(doSomething3));
```

This can also cause a little confusion, as there's a lot of magic under the hood here to make this work.

## State

Another undesireable property of Promises is that they maintain an internal state.  This usually doesn't cause problems, as you rarely reuse promises, but it is possible.


## Interoperability

Bridging the gap between promises and callback-based code can be tedious.  Oftentimes you can't do Promises all the way down, because at some point you need lazy evaluation, so you use a promise generator with a callback.

As well, Promises can only resolve to one value, whereas callbacks can return any number of values, which can add additional work to manually manipulate results.

## Proposed Alternative

To address asynchronous issues in a simpler way, I propose an alternative to Promises and async/await:

Move your callback to the front.

``` JavaScript
function doSomething(value, callback) {...} // don't do this

function doSomething2(callback, value) {...} // do this
```

Why?  A big part of the reason that callback-style asynchronous code can be annoying to compose is differing function signatures.  This is the same reason all callbacks have settled on having the error parameter as the first argument, so that the callbacks can handle errors regardless of nature of the result.

Once you move the callback to the front, it gets a lot easier to write higher-order functions that compose "chains" of callback-style functions together asynchronously.  I wrote a library of quite a few of them myself: [uchain](https://github.com/somesocks/uchain).

uchain is a collection of helpers that take in asynchronouse task functions and compose them in various asynchronous ways.  Its all functions, all the way down.

Using uchain:

``` JavaScript
const { InSeries } = module.exports;

// doSomethingWithPromises is a promise generator function
function doSomethingWithPromises(value, callback) {
  return Promise.resolve(value)
  .then((value) => value)
  .then((value) => value)
  .then((value) => value)
  .then(callback);
}

// prints out "[1, 2, 3]" eventually
doSomethingWithPromises([1, 2, 3], console.log);

// InSeries composes asynchronous functions,
// and provides the callbacks to chain everything together
const doSomething = InSeries(
  (callback, ...args) => callback(null, ...args),
  (callback, ...args) => callback(null, ...args),
  (callback, ...args) => callback(null, ...args)
);

// doSomething is now a function like:
// function(callback, ...args) {...}


// prints out "null, 1, 2, 3" eventually;
doSomething(console.log, 1, 2, 3);
```

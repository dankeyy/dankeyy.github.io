---
layout: "post"
title: "next(generators)"
permalink: "next-gen-generators"
---

# Table of Contents
* Into
* yield and return from the same function
* coroutines, and not the async ones
* A yield yield conundrum
* yield as a pair of scissors

___
&nbsp;
# Quick Intro & Motivation
One of python's best features is, in my opinion, generator. I believe it allows for some pretty concise and expressive code, as well as handing out an ergonomic handle to lazy evaluation when needed.

That being said, there's a lot more to them than meets the eye. You could do a lot more than to just iterate and collect data.

 In this article I will explore some lesser known, (/used even) capabilities of generators in CPython. Going from relatively basic stuff over to not-too-complicated but a bit more-complicated stuff.

Requires basic understanding of generators and common use cases, maybe some decorators and higher order functions, but not something too extreme. 

I don't know if everything is gonna be super practical but I hope you'll find it entertaining anyway.


&nbsp;
# a look inside

Before we continue, it's good to know the basics of `iterables`, `iterators` and `iteration` in general, over sequences and generators alike. 

> _An `iterable` is any Python object capable of returning its members one at a time, permitting it to be iterated over in a for-loop. Familiar examples of iterables include lists, tuples, and strings - any such sequence can be iterated over in a for-loop._

There are two methods an object can implement to achieve the title `Iterable`:
1.  `__getitem__` : meaning it enables slicing, indexing and will raise an `IndexError` when you're no longer trying to access a valid index, sometimes called a sequence. Objects that implement such behavior, to name a few, are `list`, `tuple`, `str`.

2. `__iter__` meaning you can iterate over its values one after the other. Notice this behavior can absolutely coincide with that of an object that already implements `__getitem__` (as every data structures mentioned above does), **but** not necessarily, as we see in the `set` data structure that as we know does not allow slicing nor indexing as it is by nature an unordered collection. 
   
   More importantly for our purposes, this is the behavior of a `generator`. We want it to be lazy, to only do what its supposed to do and yield what it supposed to yield _only_ at each iteration, occupying an iterative nature and thus implementing an `__iter__` function.
   
   By definition we will not be able to tell its next-next value at a glance, we will not be able to take the second half of it without going through the first, as it hasn't been evaluated yet. So it will not implement `__getitem__`.


In a slight change of tone let's take a look at the following code:
```python
for _ in it:
    pass
```
How the for loop knows when to stop?

Well you could say, if an indexed data structure underlies, length could be received by calling `len()`  so it could just handle the indexing and retrieve the values, translating theoretically to something like
```python
for i in range(len(it)): ... # do stuff with it[i]
```

But what about a situation where your Iterable does not implement `__len__` nor `__getitem__`, how will you then know when to stop?

##### You may already see where I'm going with this, but if you don't it's important that you encounter the following implementation & exceptions before further explorations.

Basically you're doing this:
```python
x = iter(it)
while True:
    try: next(x)
    except StopIteration: break

```

Some things to unpack here:
`iter` - a built-in function that accepts an object and returns a corresponding iterator object, provided by the object's implementation of the `__iter__` method.

The most important thing to notice here is of course- the StopIteration Error.
`StopIteration` is a built-in Exception that an iterator's `__next__` raises while trying to get the next value when there are none left.

So basically all that's going on is that the for loop abstracts away the part where you have to manually listen for a StopIteration, gives you back values if they are indeed yielded out, and if not, it just stops. Pretty elegant.


> side note: in latest versions of python, `StopIteration` exception raised from generator code will be converted to RuntimeError. See [here](https://docs.python.org/3/library/exceptions.html#StopIteration) and in the relevant PEPs linked inside.

Now that we got that out of the way, let's take this in a different direction.

It's kinda common knowledge that an iter

&nbsp;

# yield AND return?
Usually we make a distinction between generator function's and regular function's semantics.

The distinction being `yield` is the keyword we use to output values back to the caller in a _generator function_ (in a routine manner) and `return` to give back a value in a _regular function_.
So what if we use both `yield` and `return` in the same function?

*The following is a property of python 3 only.*

Let's create such a function, try to catch its values and examine its behavior.

```python
In [1]: def rgen():
   ...:     yield "came from yield"
   ...:     return "came from return"
```
Now let's think how we can get those values.
the yielded value as usual will be obtained by exhausting the generator object.
as in `next(rgen())`. but what about the return value? 

So if we take a look at [PEP-255](https://www.python.org/dev/peps/pep-0255/), it says 
>When a return statement is encountered, control proceeds as in any function return, executing the appropriate finally clauses (if any exist). Then a StopIteration exception is raised, signalling that the iterator is exhausted.

Ok so that's fine, it'll raise a StopIteration exception signaling we're done. if that's true then.. let's try and catch it.
```python
In [2]: g = rgen()
```
first we have to make it go to the the yield statement as in any generator:
```python
In [3]: next(g)
```

which outputs, as expected:
```
came from yield
```
now to the interesting part;
> A StopIteration attribute was added in v3.3, namely `value` ([source](https://docs.python.org/3/library/exceptions.html#StopIteration)). This attribute will be the holder of our value.

```python
In [4]: try: 
            print(next(g))
   ...: except StopIteration as e: 
            print(e.value)
```
We run it and indeed a the return raised a StopIteration exception which we successfully caught, printing:
```
came from return 
```

So that's neat. Notice the meaning behind the return in this context, as said in the [pep](https://www.python.org/dev/peps/pep-0255/#then-why-not-allow-an-expression-on-return-too): _"I'm done, but I have one final useful value to return too, and this is it"_, with an emphasis on _I'm done_, because any yield **after** the return statement **will not** be executed.

Note that this thing, generally speaking, is equivalent to doing `raise StopIteration(value)`, so the applications are pretty similar. 

If you wish to terminate a generator function early and give an indication as to what happened or some sort of a resulting value, that may be the way to go.

Though maybe in most implementations of a generator function you'd have a different mechanism for stopping at the right time, I personally have found it useful/ elegant, for instance, in a situation like a recursive generator function in which you wish to early terminate inner iteration.

Overall pretty neat feature.

&nbsp;

# generator's lost brother, the coroutine
##### not the async one
Introduced in [PEP-342](https://www.python.org/dev/peps/pep-0342/), coroutines are somewhat of an obscure feature of python, more often than not, discarded on tutorials covering generators.
And that's a shame, because useful or unuseful as you'll find it, it's kind of a cool concept.

In its essence, a coroutine is a generator, using the syntax and nature of the generator, but acts in a somewhat reversed manner. Instead of spitting out values, the coroutine takes them in.

Let's clarify with an example:
```py
def f():
    print('listening...')

    x = yield
    print(f"I received {x}!")
```

Kinda weird in a glance, like what is the yield doing on a right side of an assignment?

I said a coroutine would take a values in. So what we'll do here is send a value through the yield placing it in x. The way we're going to do that is by the `send` method (provided by the beloved pep-342).

```py
>>> x = f()
>>> next(x) # first we must advance the function to the yield statement
listening...
>>> x.send()
I received a greeting!
# followed by a nasty StopIteration error
```
The send method accepts the argument and sends it to the coroutine then advances to the next yield statement. If there is none, a StopIteration error will be raised.

You could also send a value to a regular generator, but the value you get back would just be the thing it yields.

Note that it's recommended to `.close()` the coroutine after you're done (though the gc will probably handle it).

Another side-note because it was introduced in the same pep discussed and may be relevant later- you can throw or in a way inject an exception as if it was raised inside the coroutine. 
Meaning we could `x.throw(RunTimeError, "something's gone wrong")` for example and it'd behave as if the error originated from the suspension point at the yield statement
It's basically just pinpointing an error from outside to the belly of the residing coroutine.

--

A common example given on this subject is a grep coroutine to which you send lines and get an answer as to whether or not the query was found on line, but I don't feel like going through that, you are welcomed to implement such function and show me if you feel like it though. More practical examples such as a scheduler and an echo server can be found [here](https://www.python.org/dev/peps/pep-0342/#examples).

What I want to discuss is a simple misguided bad idea I had which has let me to better understand the concept and was pretty entertaining in my opinion.

# A yield yield conundrum
## understanding by a misunderstanding
When I first encountered the concept of generator-coroutine I had an idea, what if we had make a function to be a coroutine and a generator at the same time?

I remember at the time I've read some text about the subject that mentioned something like this will lead to weird behavior, might make your mind bend and other crazy disclaimers eventually leading it to not even try and cover the topic.

Perhaps I should have listened, but I think not.

The idea was extremely simple: make a function what yields the `(yield)` such that when you send value to the function it will yield it back to you. Basically an echo generator-coroutine.
```python
def f():
    while True:
     yield (yield)
```
 > note we have to put the second `yield` in brackets to let the lexer know it's an expression (we would later send a value to) rather than just the keyword `yield` which will kinda entail we're trying to yield the yield keyword and result in a syntax error.

Let's test this out:
```py
In [7]: x = f()

In [8]: next(x)

In [9]: x.send('hello')
Out[9]: 'hello'

In [10]: x.send('hello')

In [11]: x.send('hello')
Out[11]: 'hello'

In [12]: x.send('hello')

In [13]: x.send('hello')
Out[13]: 'hello'

```
Seemingly it only responds to every other message we pass it. What's going on?

To make things clearer, I will mention I used ipython in the examples above, in which if the response is None, it just wouldn't display it.

So it's not that it doesn't respond to every other send, it's that every other send yields back a None.
Why?



So we can begin to understand by taking a look at the disassembly:

```py
In [14]: from dis import dis

In [14]: dis(f)
  3     >>    0 LOAD_CONST               0 (None)
              2 YIELD_VALUE
              4 YIELD_VALUE
              6 POP_TOP
              8 JUMP_ABSOLUTE            0
             10 LOAD_CONST               0 (None)
             12 RETURN_VALUE
```

We thought it'll be all rainbows and sunshines, we would just send a value to the second yield and the first yield will take it and yield it back to us.
But as we see, it for some reason first loads the const `None` then yields stuff out.

According to pep-325:
> The yield-statement will be allowed to be used on the right-hand side of an assignment; in that case it is referred to as yield-expression. The value of this yield-expression is None unless send() was called with a non-None argument.

What's actually going on is two things:
1. The first `yield` yields None, being that the `(yield)` evaluates to None.
2. The second yield yields the value sent to the first `yield`, that being our argument to the `send` method. 

To draw the two points together - the first always outputs None and receives some value. The second is always outputting the former value and ignoring input. 
Remember- yield *always* has both input & output, both of which can be None. 

If you think about it, it doesn't make sense for it to be any other way.  We naively expected it to stop after the first yield, wait for us to send value to the second (yield) and echo back, but.. that's not really reasonable considering the nature of the generator, just like the pep says "_Blocks in Python are not compiled into thunks; rather, yield suspends execution of the generator's frame._". 

Of course it wouldn't wait for our response, it's a generator that already took control! the second yield has to have a default value in order for the generator to yield something back to us. 

I spent too much time trying to figure this out on my own when the answer was under my nose in the pep all along just waiting to be read. That being said, I think it was a nice trigger to a- remember to RTFM and b- actually understand how control transfers and the nature of generators & coroutines.

## A fix
With the understanding we've acquired, can we fix it?
Well yeah, we know by now a coroutine has both an input and an output. So granted we wouldn't have a cool yield yield but by understanding that the behavior we were looking for was already deeply rooted in the coroutine, we could just do-

```py
def f(): 
    while True:
        v = yield v
```
Making the yield take v as an input and an output interchangeably.


# yield as a pair of scissors

If you think about it, besides handling iteration and yielding out values, generators have another really interesting property- the can hold state. you could pass control to a generator function and it would halt until you actively advance it further.

How does this apply?

Let's think about this recurring phenomena- 

you open a file -> you close a file,

you acquire a lock -> you release a lock,

you start a timer -> you end a timer,

you open a socket -> you close a socket

etc.

You may guess where I'm going with this - context managers, "the thing that relieves you the worries of closing stuff after you finish, the `with block`".

That can be implemented as a class with the dunder methods `__enter__` and `__exit__`. Let's say for example we want to create a temp directory, meaning we create a new folder, do some stuff in it, then deleting it. An implementation of that could go like this:

```py
import tempfile
import shutil

class Tempdir(object):

    def __enter__(self):
        self.dirname = tempfile.mktemp()
        return self.dirname

    def __exit__(self, exc, val, tb):
        shutil.rmtree(self.dirname)
```
And that's great and all, but pretty verbose to implement for every context manager we need.

What if we abstract out the class and provide a simpler interface for creating those sorts of context managers?

## **Game plan**:
We're going to base this thing on a generator.
We know a yield statement can in a way pause a function, we can think of it as cutting it to two pieces- what comes before, and what comes after. As mentioned before _it would halt until you actively advance it further_. 

That's the goal here.
We're gonna make an interface that wraps around a generator function in which we're doing stuff at the entry point (could be opening a file, starting a timer, whatever), then yielding after it to mark the halfpoint, after which we merely clean up (closing something, ending a timer, etc), with as little boilerplate as possible.

We start by creating a class that entails the underlying `__enter__` and `__exit__` methods on the generator object we would later cover with a wrapper function.
```py
class ContextManager:

    # pre yield
    def __enter__():
        try: 
            next(self.gen) # to advance it to the yield statement
        except StopIteration:
            raise RunTimeError("didn't yield")
    
    # post yield
    def __exit__():
        """ the implementation for this function kinda has to be somewhat convoluted
        and handle various edge cases. so we'll just skip it for now"""
        
```
Afterwards we just need a function that'll wrap the class, conveniently with `functools.wraps`, simply as-

```py
def contextmanager(f):
    @wraps(func)
    def helper(*args, **kwds):
        return ContextManager(func, args, kwds)
    return helper

```
> if you're not familiar with the above sort of implementation i recommend googling on higher order functions & decorators in python

After we got that we can use contextmanager as a decorator and implement contextmanagers simply as functions wrapped by it.

We can implement the Tempdir we wrote earlier as the following:

```py
@contextmanager
def tempdir():
    tmpdir = tempfile.mktemp()

    try: yield tmpdir
    finally: shutil.rmtree(outdir)


```
Such that it tries to yield, and if an error was suppressed or not, we remove the tmpdir we created earlier.

of course we can later use this temp folder as:

```py
with tempdir as tmp:
    ... # messing with stuff inside the directory
```


The contextmanager wrapper acts as an abstraction to put the pieces together behind the scenes and give us the bare bones of what we want to be dealing with,and a very elegant at that, if you ask me. 

This is not actually a new concept, it's precisely the way `contextlib.contextmanager` function works, albeit more complex as it handles several more edge cases than we discussed.

Two key takeaways:
1. We can make cool context managers easily with `@contextmannager`.
2. And this is my favorite- we've exemplified a whole different kind of use case for generators. We're using the yield to do something that isn't at all like its ordinary use.There is no iterating over some sequence/ messing with concurrency or anything like that here. The generator merely acts like a mediator between entering to exiting.




to be continued?
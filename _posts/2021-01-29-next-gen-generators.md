---
layout: "post"
title: "next(generators)"
permalink: "next-gen-generators"
---

## Table of Contents ## can add some more info to intro. look at the description of dabeez lecture
* Introduction 
* Quick Recap
* subroutines
* Data pipelines
* yield and return from the same function
* coroutines, and not the async ones
* coexistence of generators and coroutines #remember to talk about yield (yield). irc chat in tryhards/ircchats/yieldyield.md
* yield as a state holder
* yield as a pair of scissors

___
&nbsp;
## Introduction
This is an article about more advanced and/or lesser known abilities and uses of generators in CPython, going gradually from the simplest stuff to not-too-complicated but more-complicated stuff, with a few interesting things to observe along the way.

Hopefully at the end of this you'll have a better understanding of how generators work and how you can manipulate them at your favor using a few new methods and techniques.

Notice this article's primary focus is mostly on generators but we'll dive a bit into iteration/ concurrency/ control flow etc while we're at it.

Not everything here would be super practical but I think exploring this stuff just for the sake of it is enough interesting as it is to justify going down that road.

Anyway, this is gonna be a long one, so feel free to divide its reading by chapters or whatever suits you. :D

---

&nbsp;
## Recap 
# part 1

So you've learned about generators and the yield keyword.

You probably know how to do neat stuff like
```python
def f(n):
    for x in range(2, n, 2):
        yield x
```

Maybe you're a bit more fluent by now so you know stuff like `yield from`
```python
def f(n):
    yield from range(2, n, 2)
```

Maybe even that function is too much for you, so you'd go for a `generator expression`
```python
 f = (x for x in range(2, n , 2))
 # perhaps a quick lambda if n isn't in scope
 f = lambda n: (x for x in range(2, n , 2))
```

You probably also know how to actually use them
```python
for x in f(101):
    print(x)
# I tend to go for a hundred and one next()־s, but you do you
```

You might know other ways to manipulate iteration
```python
print(list(f()))
```

You might even know about cool features like unpacking & unpacking a generator
```python
print(*f())
```
&nbsp;

*"ACKTUALLY you can just unpack the range sequence into the print `print(*range(2, n, 2))`. what are you a noob?"*

Yeah fine, but that was one smooth recap. 


&nbsp;
# part 2
Before we play around any further, it's important to understand the basics of iterators, iterable and iteration in general (over sequences and generators alike). 

There are two methods an object can implement to achieve the title `Iterable`:
1.  `__getitem__` : meaning it enables slicing, indexing and will raise an `IndexError` when you're no longer trying to access a valid index, sometimes called a sequence.

2. `__iter__` meaning you can iterate over its values one after the other.

In any case, the above Iterable will return an `Iterator`, one that implements a `__next__` method that will return as the next item in line from the Iterable.

Take a look at the following code:
```python
for i in it:
    pass
```
Seems kinda redundant but hold on. 
How does the for loop know when to stop?

Well, you could argue that such thing it possible because you know its length is `len()`, or rather `__len__`. Such that you can implement it simply running a loop exactly that _len_ number of times. 
```python
for i in range(len(it)): ... # do stuff with it[i]
```
And you'd be correct. Sometimes.

Think for a second about a situation where your Iterable does not implement `__len__`, how will you know how to stop then?

##### You may already see where I'm going with this, but if you don't it's important that you encounter the following implementation & errors before further explorations.

Basically, you're doing this:
```python
x = iter(it)
while True:
    try: i = next(x)
    except StopIteration: break

```
> Side note to those not familiar with `iter` - a built-in function that accepts an object and returns an iterator object provided the object implements the `__iter__` method. Plenty of resources and fine docs on this topic can be found online. 


The most important thing to notice here is of course- the StopIteration Error.
`StopIteration` is a built-in Exception that an iterator's `__next__` raises while trying to get the next value when there aren't none left.


> Another side note: in latest versions of python, `StopIteration` exception raised from generator code will be converted to RuntimeError. See [here](https://docs.python.org/3/library/exceptions.html#StopIteration) and in the relevant PEPs linked inside.

Alright I think this is a nice place to stop at, so lets stop and take this thing in a slightly different direction.

If that's roughly the point where you're at in your understanding of generators and iteration, hold on because there's more, a lot more.

---
&nbsp;

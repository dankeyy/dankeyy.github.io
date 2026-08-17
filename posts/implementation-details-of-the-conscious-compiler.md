### disclaimer
I am an expert on none of the following. I'm about to ramble on things I have nothing but intuition about. I have, however, been thinking about these questions so long, so this post will be the outlet of those thoughts.

Also, the post somewhat requires an understanding of compiler architecture but not really, you can just google whatever term is unfamiliar and move on.

---

### the point
In recent years I've been getting the feeling that there are some uncanny similarities between compilers and minds.  
In this post I'm going to attempt to draw the parallels.

--- 
## the trigger
In my country 5 years after getting your license you have to physically go to a 2-day refreshment course on road safety and general driving guidelines. I've recently went through it.

In the course there is a chapter on "indicative signs", these are things you should look out for that could cause a near-future accident.  
At some point I lost focus of the actual lecture, the examples caught my attention. I will give 2:

1. Suppose there's a car stopped on a road with its trunk open. From the trunk being open we can derive that the driver might, in the near-future, exit out of the car. If we are driving in a car behind the guy in this situation, we need to be more careful when passing by the car as to not hit the potentially exiting driver.
2. If it's nighttime and, let's say, the street lights ahead are broken, you can derive that the road ahead is dangerous and slow down (something like that).

What caught me is that both of the examples show how we do inference.
In the first example, from the minor fact that the trunk is open we infer a broader risk in the road.
In the second example, from the nightly dark environment, we infer our careful attention is needed.

You may ask at this point where's the punchline.

The punchline is that this is exactly how many modern type systems work! Specifically, I see it as analogous to bidirectional type checking.
In short, the "directions" are:
1. Downstream: type information flows down from the environment to the expression, for instance:
```
let x = f(2) 
in x + 3
where 
    f : int -> int
```
f is defined in the environment as a function from int to int, thus by calling f with the integer 2, we get an integer, and we can infer the type of x is int.
2. Upstream: type information flows up from the expression to the environment:
```
let f = \x -> x 
in f(z)
where 
    z = "hello"
```
Here, z is defined as the string literal "hello", from the known language semantics we derive the type of z is str. We also know f takes an expression of unknown type T and returns an expression of the same type T. Filling in the blanks we now infer that in environment e, f is a function from string to string.

(In practice yes this identity function can be generalized first by the type checker before instantiating it for the string type at the callsite, It's besides the point, but maybe an interesting different one.)

I think this is an interesting aspect of the mind, and while writing this I recall the invisible gorilla experiment (https://en.wikipedia.org/wiki/The_Invisible_Gorilla) - it seems that we can hyper-focus on the environment (x)or an object in the environment.  
In compiler terms we could say perception has a parsing "pass" that is linear and single threaded.  
it's not immediately obvious why that is. We can easily propose multiple evolutionary and psychological reasons for it, but from an implementation perspective, I believe the answer is identical to why we kind of settled on bidirectional type checking - type systems have become capable enough that sometimes full inference is computationally too expensive at best and simply undecidable at worst. So we do bidirectional type checking.  
The experiment is beautifully done because it shows that sometimes reality doesn't let you do a second pass. You had one chance of checking and it was either upstream or downstream.

## the motivation
Besides being fun little patterns why are parallels interesting?

We have 2 "things", one is known, one is unknown. By understanding the design of the known, the limitations & capabilities of the known, we may discover interesting characteristics of the unknown. Obviously the fact two things are similar in one aspect does not mean they are similar in every aspect or even another aspect, but while exploring the known and noticing patterns we can often derive more sub-patterns that we can project unto the unknown domain and explain previously unexplained phenomena and behaviors.

That is the motivation, now we can move on.

## bird's eye
We want to understand understanding. So the correct order, I think, is the order we understand things.

I believe there is some objective reality. I don't believe we can comprehend it. 

We have our senses that I think are like I/O translation machines. They take some aspect of reality as some serialized input (who is the serializer? Maybe the serializer is baked into physics?) and pass them on to the brain which deserializes it.

The interesting thing to figure out now is why this process is lossy. Why can you and another person look at the same thing and comprehend it completely differently? Well let's think:
- The hardware of the senses differs, e.g. some people are color blind.
- The immediate (will argue for this word later) deserializers differ. The program of the senses can be outdated. E.g I cannot understand what I'm looking at is a desk until I've seen at least once a desk, attached meaning to its shape and stored it away somewhere in the mind.
- what the rest of this post will be about.

## semantic analysis
It might be tempting to take the NLP definition of SA. But a. This is about compilers. And b. Funnily enough I think compilers' definition is the only one broad enough to match the parallel to the SA the mind does.

As I've hinted in #the trigger section, I truly believe the mind does type checking.
I think in childhood and beyond we enhance the implementation of the conscious compiler. In fact I think of it as self modifying code (AKA SMoC).  
We add support for more and more types. A new type can be co-dependent on another already known within the compiler. I think that is why you can smell a scent and recall some dish you used to love.

The modern compiler meaning of semantic analysis could differ between implementations and what we choose to define its scope, but as I see it, the goal is to take in an un-annotated AST and output an annotated AST that is imbued with meaning.  
This includes analyzing the types of things, looking up existing symbols , raising an exception when things are unfamiliar, giving meaning to what things are.

Circling back, I think this is what we do with the structured input from our senses. At some point in perception there exists an AST of our perceived state of reality sitting in our mind's RAM that we give meaning to by the process of semantic analysis.


## down the line
What about lowering?  
I think that humans are acting machines, I think reality is a curated selection of inputs that preempt us to act. We do not compile reality to some static artifact, we compile reality to an instruction set. In turn, there are multiple EXECs that go on to distribute the acts our minds and brains have decided upon, whether it'd be to move our feet, hands, talk, make a frown or wash the dishes.

But also we don't just generate instructions on how to act, we generate instructions on how to think.  
We haven't in this post fully decided what thoughts are, but for this point let's say they're some intermediate representation (IR) in the compiler:  
If thoughts eventually compile to actions, then there must be some runtime code generation going on.
Arguably we compile in https://en.wikipedia.org/wiki/Continuation-passing_style such that we always have a continuation that preempts our next thought? 

Interesting questions right? Likely we'll never know the answers to, but I believe exploring the ideas we yield by thinking about them can help us overcome bugs in the conscious compiler, of which existence I'm certain of.


## what about reflection?
The most incredible thing about the mind is its ability to self-reflect.  
We think so much about our past, present and future.
We think so much on how we act, on our mistakes, on our goals, on every aspect of ourselves.  
It is the cornerstone of the mind. 

What can the implementation details of the conscious compiler teach us about our consciousness?  

In compilers, when we talk about reflection and meta-programming in compilers, we talk about observing and / or modifying code at one out of three possible levels (mainly):
1. Text or lexical tokens level - code not yet imbued with meaning, plain text, the most raw representation (tokens being one step above, simply after grouping some characters into "words").
2. AST level (in macros context often called "hygenic macros") - parsed, logically broken down by the rules of the language.
3. Type level (in macros context often called template metaprogramming, but to be honest just generics or any form of polymorphism is a kind of type-level metaprogramming in my opinion) - you can imagine this step sitting at the level of the annotated AST. Here, we create an abstraction that is correct for multiple "kinds" of things.

Why am I rambling on about different kinds of metaprogramming?  
You know the feeling when you remember some cringe situation and you just want the thought to leave your mind? Maybe you even distract yourself to make it go away?  
I think that when you do that, when you don't let it sink in, you operate on lexemes, instead of on the annotated AST.  
Because you do that, you only get the surface level pain and aim to dismiss it.  
I think it's an incredible mechanism of the mind that tries to self correct by "reminding" you of the situation, with the goal of it being internalized, processed and fixed in the conscious compiler.  
But a bug there, a fear, causes us to push it away, instead of letting it parse through and fix what is needed to be fixed.

Sidenote 1: to that end I think that's what dreams are for aswell, some kind of fuzzing tests over the compiler, to see how it responds to different situations (inputs) and fix bad behaviors (outputs).  
And just like a sporadic thought, it only works if you let it sink through.


Sidenote 2: All the above being compile time metaprogramming, we must not forget about runtime metaprogramming, sometimes languages (often with a heavy runtime environment) allow modifying and inspecting code as it runs.  
That I think is analogous to the ability of meditating people, who become observant of their emotions as they come in real-time.
 
 
---
There's a thousand things more that could be said and explored here but I think this is a good place to stop.  
Many of my claims here could be stupid and wrong, but the goal is not me being right, rather its to provoke thought so I hope to have gotten at least that.

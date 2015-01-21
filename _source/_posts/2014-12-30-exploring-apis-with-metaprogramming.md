---
layout: post
title:  "Exploring APIs with Metaprogramming"
date:   2014-12-30
image: /assets/article_images/2014-12-30-exploring-apis-with-metaprogramming/header.jpg
excerpt: "Introducing Blanket, a dead simple API client.
The article explores the concept of Metaprogramming and how it can be implemented in Ruby."
---

The [Wikipedia entry](http://en.wikipedia.org/wiki/Metaprogramming) for "metaprogramming" defines it as:
>(…) the writing of computer programs with the ability to treat programs as their data. It means that a program could be designed to read, generate, analyse and/or transform other programs, and even modify itself while running.

For the purposes of this article, we can define metaprogramming as the ability to **write code that writes code**. I’ve been dwelling on this topic a lot ever since I started playing with the [Elixir language](http://elixir-lang.org/), however, after having discussed RESTful API design with my co-workers during the last few weeks, I set out to build a simple tool that allows one to easily explore and consume a web API. The result is a Ruby gem affectionately called [Blanket](https://github.com/inf0rmer/blanket). Here’s an example of Blanket in use, together with the [Github API](https://developer.github.com/v3/):

{% gist inf0rmer/78a84c0faa1a087ddf24 %}

# Dynamic method dispatching
Once you’ve wrapped an API with Blanket, every method you call on the wrapper is added as a part of the URL. Only when you call any of the action methods (`GET`, `POST`, `PUT`, `PATCH` and `DELETE`) is the request actually executed. If you pass a parameter to a method such as users, it is appended after it as a resource identifier, following the REST convention of `:resource/:id`.

The actual code that does this is surprisingly small and terse, thanks to Ruby’s support for dynamic method dispatch via **`method_missing`**. If you define this method in one of your classes, all messages sent to that object that are not statically defined get rerouted to the handler you’ve defined. At the time of writing, Blanket’s method missing reads as such:

{% gist inf0rmer/fcc26bb9d6045f72d4df %}

Calling any undefined method on a `Blanket::Wrapper` object will return a new instance wrapped with the current URL. The fact that these objects are, for all intents and purposes, immutable is an aspect that greatly lowers the complexity of the program, but that is enough material for another post ☺.

This class currently spans around 90 LOC, with most of it dedicated to private helper methods. The `Wrapper` class contains five other public methods though: the RESTful request actions. These, however, are not statically defined in the code either, they are generated at runtime.

# Code that writes code
Ruby objects have another very useful method for metaprogramming called **`define_method`**. This allows you to define methods in your class at runtime, as if out of thin air. To generate the request actions Blanket defines a small private "macro" (heavy quotes around that as Ruby does not really support macros, this just makes it look like one):

{% gist inf0rmer/c3034198f813d92492f9 %}

The `request` method is where the actual HTTP request happens, so this macro is just a way to conveniently add all of the similar request actions at runtime. Here’s how all the relevant methods are added:

{% gist inf0rmer/4321e9b103d027a14b22 %}

# Classes can be dynamic too!
While developing Exception raising support, I came across a fun problem: I wanted to expose specific `Blanket::Exception` classes for well known HTTP status codes such as `400`, `404`, `500`, you get the drift. This would make capturing and handling different types of exceptions easier.

One could surely just type all this code in, but there are about 60 well-known status codes and I don’t really enjoy repetitive tasks that much. Let’s take a map of status codes, using the code as a key and the value as it’s meaning in a human readable format:

{% gist inf0rmer/4b00db3eaf14affba8e3 %}

Let’s get on to the fun part: generating `Blanket::Exception` subclasses for each of these!

{% gist inf0rmer/147dd9d5c52f2ed77aae %}

There are a few things happening here. For each code/message pair, we’re creating a new Class inheriting from `Exception`, defining a method in it, setting it as a constant and finally, adding it to another map, `EXCEPTIONS_MAP`. This last step allows to raise a new 500 Exception like this:

{% gist inf0rmer/8148341963c0b52d1efc %}

Because we also defined each of these exceptions as a constant, you could also do this directly:

{% gist inf0rmer/b73d0c8a84e0d3e197b1 %}

# Documenting your endeavours
Writing code that writes code can obviously be very powerful, but software cannot be written solely for the computer to understand. Because your code will, at some point, probably be used by other human beings, documenting how it works is of paramount importance. **But how do you document that which is not there?**

[YARD](http://yardoc.org/) is a documentation tool for Ruby projects. Here’s how you may generally document a static method:

{% gist inf0rmer/559c04cb99f2462b830e %}

Remember the `add_action` "macro" we talked about earlier, used to define the various RESTful action methods? We can use YARD’s `@macro` directive to dynamically create documentation for all invocations of `add_action`:

{% gist inf0rmer/7bfbdb91a5f01e8b56c4 %}

When we call `add_action` with `:get`, for example, documentation would be created for a public method `get`, with the text *Performs a get request on the wrapped URL* as well as all available parameters and return types.

# Wrapping it all up
Metaprogramming allows you to build wonderfully expressive interfaces while writing as little code as possible. In the case of Blanket, the whole project is comprised of three classes weighing around 40–90 LOC each, including documentation. For such a little utility, I would argue it packs a whole lot of functionality and delivers in a very terse and declarative way.

While it can be a powerful tool, in most cases you should exercise caution and restraint when using it, as its misuse can quickly muddle a codebase and lead to confused and frustrated collaborators trying to make sense of your highly abstracted code.

The next challenge? What if you could do this in Javascript? Every piece of software that can be written in Javascript will eventually be written in Javascript, so why not give it a go? Stay tuned!

Header Photo by [Elvis Pucar](https://www.flickr.com/photos/87485176@N08/15062733327/in/photolist-oX3rQK-pRjCbP-o8Zvys-o7sUGi-pyJSZC-qdic3a-pRSkKv-pmhgiG-phhvdB-pyv1Ke-phiMJG-pqsTpJ-qughm9-pzD5mY-pSacjU-pwHhaA-phjheh-phiZgj-pzDHf7-pPXZuQ-pzExwB-pCErwx-pheQo6-phigXe-phjcfg-pyur2n-pyKGsr-pwLuHq-phjwPr-oz5kXU-phiDb8-pyMnpc-phi52o-phh53B-pyPj2g-phfqux-oHnU8G-oVdcUh-pxFHgE-qvAG9K-phjB1H-pyu5mK-pyNTpk-phik3y-pyKQ2w-phhbwZ-pyLy8i-pzFLjm-oVgKgD-pS5j6n)

# Flutter Sticky Bottom Button: Beyond the FloatingActionButton

Flutter gives us the `FloatingActionButton`, and don’t get me wrong, it’s great.

But sometimes… it’s just not enough.

Sometimes we want more control over how and when a button appears. Maybe we want it to stick to the bottom of the screen only for a specific section. And when we finally reach the bottom of that section, we want it to stay there, in its natural position, without floating awkwardly above the content.

There are countless scenarios where this behavior makes sense. I won’t limit your imagination with just one. Today, I’ll show you how to create a smart sticky button, one that stays pinned exactly as long as you want it to. And more importantly, we’re not just going to build it. **We’re going to understand every single detail behind it.** By the end of this article, you’ll be able to take this pattern and adapt it to anything you need. Let’s begin.

## What we are going to build
Before we dive into the code, let’s first see the final result. Here's a preview:

[Video with the feature]

What exactly is going on here:
- When the button is visible in its natural position → nothing special happens.
- As soon as you scroll and the button moves off screen → it smoothly pins itself to the bottom.
- When you scroll back down and reach the button’s original position → the pinned version disappears and the inline one takes over again. 

**No layout shifts. No jumpy behavior. No weird overlap.**

And the best part? We’re not using any external packages. We will use all the available tools from Flutter. We need `Stack`, `ScrollController` and `GlobalKey` together with some math. Enough with the preview, let's get to the coding part!

## How to build this actually?
Before we make anything sticky, we need a normal screen. Just a simple scrollable layout with a button at the bottom.

Here’s our starting point:

```
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned Bottom Button')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Column(
                spacing: 12,
                children: List.generate(
                  20,
                  (index) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 205, 206, 207),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 1, color: Colors.black),
                    ),
                    child: Text(
                      "Random List Item $index",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Pinned Button"),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Random content at the bottom of the page."),
            ],
          ),
        ),
      ),
    );
  }
}
```
### What Do We Have So Far?
Let’s break this down. We have:
- A `SingleChildScrollView`
- A `Column` with dummy content
- A button placed naturally at the bottom
- Some extra content after the button

Right now, the button behaves normally. If you scroll up, it disappears. If you scroll down, you see it again.

There is nothing **“sticky”** about it.

### Introduce the StatefulWidget
Right now, our screen is a `StatelessWidget`. And that makes sense, until we realize something important. We want the UI to react to scroll changes. The moment we say **“react”**, we introduce state.

Our button visibility will depend on:
- Whether the screen is scrollable
- Where the inline button currently is
- Whether it reached the fixed bottom position

All of those values change over time. And when something changes over time in Flutter… we need a `StatefulWidget`. With that change, we get access to important methods like `initState()`. Let's see how we use them:

```
class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  bool _isScrollable = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  void _checkIfScrollable() {
    if (!_scrollController.hasClients) return;

    final isScrollable = _scrollController.position.maxScrollExtent > 0;

    setState(() {
      _isScrollable = isScrollable;
    });

    if (isScrollable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateButtonVisibility();
      });
    }
  }

  void _onScroll() {
    if (!_isScrollable) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateButtonVisibility();
    });
  }
```
#### Why we need ScrollController?
With the `SingleChildScrollView` we apply the scrolling functionality to our screen. By default, we have no idea when it actually scrolls. So, here comes the `ScrollController`!
```
SingleChildScrollView(
  controller: _scrollController,
```
Now, we have access to the scroll position, we listen to scrolls and we also have the information about how much content exceeds the screen. As you can see, this controller acts as the communication bridge between the scrollable widget and our state logic. And this line is where things become reactive:
```
_scrollController.addListener(_onScroll);
```
Every time the scroll position changes, `_onScroll()` gets called.

#### The importance of initState()
`initState()` runs exactly once, when the widget is inserted into the widget tree. This makes it the perfect place to:
- Attach listeners
- Initialize controllers
- Perform one-time setup logic

We never attach listeners inside `build()`. **Why?** Because `build()` can run many times. Think of all the "noise" we would have if we attached a listener everytime the `build()` was triggered.

#### Why Use addPostFrameCallback?
If you see inside `initState()`, we have:
```
WidgetsBinding.instance.addPostFrameCallback((_) {
  _checkIfScrollable();
});
```
Why don't we just call `_checkIfScrollable()` directly? Because when `initState()` runs, **the UI has not been laid out yet.** At that moment:
- The scroll view doesn’t know its dimensions
- The content hasn’t been measured
- `maxScrollExtent` is not reliable

If we check scroll metrics too early, we might get incorrect values. But, `addPostFrameCallback` runs after the first frame is rendered. **This guarantees that our logic runs at the correct time.**

Also, it's important to explain one more critical part of the code. Inside `_checkIfScrollable()`, we calculate:
```
final isScrollable = _scrollController.position.maxScrollExtent > 0;
```
`maxScrollExtent` represents:
> The total scrollable distance beyond the visible viewport.

If it **equals 0**:
- The content fits entirely on the screen.
- There is nothing to scroll.
- Sticky behavior is unnecessary.

If it’s **greater than 0**:
- The content exceeds the screen height.
- The screen is scrollable.
- Our sticky logic becomes relevant.

So `_isScrollable` acts as a guard. If the screen isn’t scrollable, we don’t waste time calculating button positions. It's a small optimization, **but important**. This is what makes the difference in the code afterall.

### Let's add the Sticky button
What do we have so far? Right now, we have a button that lives inside our `SingleChildScrollView`, but we need a button that will flow above all content. This functionality gets unlocked by wrapping our entire content into a `Stack`. Stack is a very powerful Widget in Flutter that lets multiple layers of content get on top of each-other. And this is exactly what we need here:
```
body: SafeArea(
  child: Stack(
    children: [
      SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Scrollable content
            SizedBox(
              key: _inlineButtonKey,
              width: double.infinity,
              child: Opacity(
                opacity: _inlineOpacity,
                child: _buildButton(),
                ),
            ),
          ],
        ),
      ),

      Positioned(
        left: 8,
        right: 8,
        bottom: 16,
        child: Opacity(
          key: _floatingButtonKey,
          opacity: _floatingOpacity,
          child: IgnorePointer(
            ignoring: _floatingOpacity == 0.0,
            child: _buildButton(),
          ),
        ),
      ),
    ],
  ),
),

  Widget _buildButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: const Color(0xFFD97757),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        "Pinned Button",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
```
We use the same button for both the floating button and our inline button, so it's better if we create a separate Widget to stay aligned in both cases. But now there are a lot of new interesting things inside the code. Why do we need keys? How do we use opacity? Let's explain everything!

#### Why Do We Need GlobalKey?
```
final GlobalKey _inlineButtonKey = GlobalKey();
final GlobalKey _floatingButtonKey = GlobalKey();
```
We attach two `GlobalKey`s to our two button widgets because this gives us access to their underlying `RenderObject`. Normally in Flutter, we don’t go that deep. We declare widgets, Flutter lays them out, and that’s it.

But in this case, we need something very specific:

We need to know the exact position of these buttons on the screen. And that information is not available at the widget level. It lives inside the rendering layer. More specifically, inside the widget’s `RenderObject`. That’s why we need a `GlobalKey`.

#### How Do We Access the Exact Location of the Buttons?
Earlier, we referenced a method called `_updateButtonVisibility()`. Now it’s time to take a closer look at it:
```
  void _updateButtonVisibility() {
    final inlineBox =
        _inlineButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final floatingBox =
        _floatingButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (inlineBox == null || floatingBox == null) return;

    final inlinePosition = inlineBox.localToGlobal(Offset.zero).dy;
    final floatingPosition = floatingBox.localToGlobal(Offset.zero).dy;

    final reachedFixedPosition = inlinePosition <= floatingPosition;

    setState(() {
      if (reachedFixedPosition) {
        _inlineOpacity = 1.0;
        _floatingOpacity = 0.0;
      } else {
        _inlineOpacity = 0.0;
        _floatingOpacity = 1.0;
      }
    });
  }
```
The key part of this method, is here:
```
    final inlinePosition = inlineBox.localToGlobal(Offset.zero).dy;
    final floatingPosition = floatingBox.localToGlobal(Offset.zero).dy;
```
Let's break down what's going on here. First of all, we use `Offset.zero`. That represents the top-left corner of the widget in its local coordinate system, which will be our **target-point**.
> Offset(0,0)

By default, a widget’s position is relative to its parent. That means if we just queried its layout position normally, we would get coordinates relative to the parent widget, **not the screen**. 

But we don’t care about the parent. We care about the screen. `localToGlobal()` converts a local coordinate into a global screen coordinate.
> Offset(24.0, 612.0)

This means:
- 24 pixels from the left side of the screen
- 612 pixels from the top of the screen

From that `Offset`, we only care about the vertical position, so we extract the `dy`. And the final result looks like this:
> inlinePosition = 612.0

#### The logic behind this calculation
The entire purpose of measuring these two positions is very simple. We want to know when both buttons are aligned vertically.
Let’s think about their behavior:
- The inline button lives inside the scroll view → **its Y position constantly changes while scrolling.**
- The floating button is positioned using Positioned(bottom: 16) → **its Y position remains stable.**

As we scroll upward:
- The inline button moves closer to the floating button’s position.
- Its `.dy` value decreases.

The moment this becomes true:
```
inlinePosition <= floatingPosition
```
It means:

The top-left corner of the inline button has reached (or passed) the top-left corner of the floating button. At that exact moment, the two buttons are aligned. And that’s when we switch visibility.

The inline button takes over. The floating button disappears.

#### Opacity toggle
Inside `setState()` we change the opacity between the two buttons. Only one of them can be visible. But why is it so important to use `Opacity` and we didn't choose to remove the unsused Widget? The reason is to avoid UI leaks. If we add/remove Widgets all the time, we may 
change layout height, cause visual jumps, or more importantly affect scroll position. **Opacity keeps layout stable.**

## Conclusion
And there you go! What started as a simple scrollable screen slowly evolved into a fully controlled sticky button pattern, built entirely with Flutter’s core tools. **No packages. No hacks.** Just a solid understanding of how layout, scrolling, and rendering work together. 

Along the way, we didn’t just “make a button stick.” We explored `StatefulWidget`, `ScrollController`, `addPostFrameCallback`, `GlobalKey` and more. This pattern might not be something you implement every day. But when you need precise scroll-aware behavior, (like checkout CTAs, smart action bars, or contextual buttons) understanding this technique gives you full control.

Hopefully, this guide didn’t just show you how to build a sticky button, but helped you better understand how Flutter thinks about layout and positioning.

If you enjoyed this article and want to stay connected, feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/thanasis-traitsis/).

If you'd like to dive deeper into the code and contribute to the project, visit the repository on [GitHub](https://github.com/Thanasis-Traitsis/flutter_spotlight).

Was this guide helpful? Consider buying me a coffee!☕️ Your contribution goes a long way in fuelling future content and projects. [Buy Me a Coffee](https://www.buymeacoffee.com/thanasis_traitsis).

Now go ahead. Play with it. Improve it. And we will catch up in the next blog!
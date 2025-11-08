# balut

## Game Screens

### Shop

The shop screen allows you to see your upgrades and a random selection of
upgrades that can be purchased with coins. Once you've made your selections,
you can continue playing.

### Game

Traditionally, X = 7, Y = 2. 7 hands, 2 rerolls.

The game is split up into X hands. For each hand, you're shown 5 dice.
For instance, you will be shown something like this:

   1 5 2 5 6

You have Y reroll opportunities. You may choose any number of dice to lock into
place when rerolling, or you may choose to skip rerolling entirely.

For instance, if you lock the two 5's, you might have upon rerolling:

   2 5 5 5 3

.. and then you choose to lock the middle 5 as well:

   1 5 5 5 6

You have no more rerolls. You now must decide on how to score your hand. You
have these options:

 - Fours (how many fours multiplied by 4),
 - Fives (how many fives multiplied by 5),
 - Sixes (how many sixes multiplied by 6),
 - Straight (scores 50),
 - Full House (one triple, one two pair, add their numbers together),
 - Choice (sum all of the numbers together),
 - Balut (all the same number; scores 30),

Once you've made your choice, your total increases by the given score.

You can only use each scoring category ONCE. You may choose one of the
categories despite it causing a score of zero, which is called scratching.

After playing each hand, and having each category assigned a number (either 0
or some non-zero number), you sum up the category scores to get the final score.

To beat the level, you must get over some determined value. When beating the
level, you go back to the shop.

## Upgrades

 - Increase number of hands
 - Increase number of rerolls
 - Change the weight of the dice (make them unfair, make some numbers more likely)
 - Change the modifiers of each combo (fours becomes number of fours
   multiplied by 5)
 - Increase number of times you can use a category (use fives twice)
 - Always score with some category regardless (for instance, you might get an
   upgrade like "always score with fours alongside your choice", so if you get
   a hand like this: 4 5 5 5 3 and you select fives, you get (3 * 5) + (1 * 4))
 - Increase number of dice in play



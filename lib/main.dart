import 'dart:math';

import 'package:flutter/material.dart';
import 'package:card_game/card_game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool smallScreen = MediaQuery.sizeOf(context).width < 700;
    return MaterialApp(
      title: 'Grid Cribbage',
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(
              fontSize: smallScreen?14:20,
              letterSpacing: 1,
              fontFamily: GoogleFonts.robotoMono().fontFamily
          )
        ),
        scaffoldBackgroundColor: const Color(0xFF2E7D32), // Green card table color
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5D4037), // A brown color for the app bar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const GridCribbage(title: 'Grid Cribbage'),
    );
  }
}

class GridCribbage extends StatefulWidget {
  const GridCribbage({super.key, required this.title});

  final String title;

  @override
  State<GridCribbage> createState() => _GridCribbageState();
}

class _GridCribbageState extends State<GridCribbage> {

  int playerTurn = 1;
  late List<List<SuitedCard>> cardsState;
  static const int playerCount = 2;
  late List<int> _scores;
  List<List<SuitedCard?>> currentGrid = List.generate(5, (_) => List.filled(5, null));
  bool _gameFinished = false;


  @override
  void initState() {
    super.initState();
    _newGame();
  }

  List<List<SuitedCard>> get initialCards {
    // Create a shuffled deck
    final deck = SuitedCard.deck..shuffle();
    // Create 25 empty lists for the 5x5 grid
    final initialGrid = List.generate(25, (_) => <SuitedCard>[]);
    // Return the grid and the deck
    return [...initialGrid, deck];
  }

  void _newGame() {
    setState(() {
      playerTurn = 1;
      _gameFinished = false;
      cardsState = initialCards;
      currentGrid = List.generate(5, (_) => List.filled(5, null));
      _scores = [0,0];
    });
  }

  void newGameDialog(BuildContext context) {
    showDialog(
      context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Are you sure yuo want to start a new game?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                  onPressed: () {
                    _newGame();
                    Navigator.of(context).pop();
                  },
                  child: Text("Yes")
              ),
            ],
          );
        }
    );
  }

  int getCardNumberValue (SuitedCard card, {for15s = false}) {
    SuitedCardValue value = card.value;
    if (value is NumberSuitedCardValue) {
      return value.value;
    } else if (value is JackSuitedCardValue) {
      return for15s?10:11;
    } else if (value is QueenSuitedCardValue) {
      return for15s?10:12;
    } else if (value is KingSuitedCardValue) {
      return for15s?10:13;
    } else if (value is AceSuitedCardValue) {
      return 1;
    }
    return 0;
  }

  int findLineScore(List<SuitedCard?> cards, int player) {
    debugPrint("");
    debugPrint("Player $player score");
    int score = 0;
    bool allSameSuit = true;
    int straight = 1;
    int longestStraight = 1;
    List<int> values = [];
    List<int> sortedValues = [];
    CardSuit? lastSuit = cards[0]?.suit;
    for (SuitedCard? card in cards) {
      if (card == null) {
        continue;
      }
      if (card.suit != lastSuit) {
        allSameSuit = false;
      } else {
        lastSuit = card.suit;
      }
      values.add(getCardNumberValue(card));
      int curDex = cards.indexOf(card);
      if (values.sum == 15) {
        debugPrint(
            "all card in line add to 15 adding 2 to player ${player}'s score");
        score += 2;
      } else if (curDex < 4) {
        List<SuitedCard?> sublist1 = cards.sublist(curDex + 1);
        for (SuitedCard? card2 in sublist1) {
          if (card2 == null) {
            continue;
          }
          if (getCardNumberValue(card2, for15s: true) +
              getCardNumberValue(card, for15s: true) == 15) {
            // check how many combinations of cards add to 15 and add 2 points to the score for each combination
            debugPrint(
                "Found a pair of cards that add to 15 adding 2 to player ${player}'s score");
            score += 2;
          }
          int curDex2 = sublist1.indexOf(card2);
          if (curDex2 < 3) {
            List<SuitedCard?> sublist2 = sublist1.sublist(curDex2 + 1);
            for (SuitedCard? card3 in sublist2) {
              if (card3 == null) {
                continue;
              }
              if (getCardNumberValue(card3, for15s: true) +
                  getCardNumberValue(card2, for15s: true) +
                  getCardNumberValue(card, for15s: true) == 15) {
                  // check how many combinations of cards add to 15 and add 2 points to the score for each combination
                  debugPrint(
                    "Found a triple of cards that add to 15 "
                        "adding 2 to player ${player}'s score");
                  score += 2;
              }
              int curDex3 = sublist2.indexOf(card3);
              if (curDex3 < 2) {
                List<SuitedCard?> sublist3 = sublist2.sublist(curDex3 + 1);
                for (SuitedCard? card4 in sublist3) {
                  if (card4 == null) {
                    continue;
                  }
                  if (getCardNumberValue(card4, for15s: true) +
                      getCardNumberValue(card3, for15s: true) +
                      getCardNumberValue(card2, for15s: true) +
                      getCardNumberValue(card, for15s: true) == 15) {
                      debugPrint(
                          "Found a quad of cards that add to 15 "
                              "adding 2 to player ${player}'s score");
                      score += 2;
                  }
                }
              }
            }
          }
        }
      }
    }
    sortedValues = values.toSet().toList();
    sortedValues.sort();
    for (int i = 0; i < sortedValues.length - 1; i++) {
      if (sortedValues[i] + 1 == sortedValues[i + 1]) {
        straight++;
        longestStraight = max(longestStraight, straight);
        debugPrint("straight increasing to $straight for player ${player}");
        if (i == sortedValues.length - 2 && sortedValues[i + 1] == 13 && sortedValues[0] == 1) {
          straight++;
          longestStraight = max(longestStraight, straight);
          debugPrint("straight with high ace increasing to $straight for player ${player}");
        }
      } else {
        longestStraight = max(longestStraight, straight);
        straight = 0;
      }
    }
    bool dupes = true;
    if (sortedValues.length < values.length) {
      // if any of the cards in values is the same as a card in sortedValues a straight can be made twice
      for (int value in values) {
        if (!sortedValues.contains(value)) {
          dupes = false;
        }
      }
    }
    for (int i = 0; i < values.length; i++) {
      List<int> subList = values.sublist(i);
      int value = values[i];
      int count = (subList.where((j) => j == value )).length;
      List<int> checkedValues = [];
      if (checkedValues.contains(value)) {
        continue;
      }
      checkedValues.add(value);
      if (count == 4) {
        // 12 points for each 4 of a kind
        debugPrint("Found a 4 of a kind of ${value}s adding 12 to player ${player}'s score");
        score += 12;
      } else if (count == 3) {
        // 6 points for each 3 of a kind
        debugPrint("Found a 3 of a kind of ${value}s adding 6 to player ${player}'s score");
        score += 6;
      } else if (count == 2) {
        // 2 points for each pair
        debugPrint("Found a pair of ${value}s adding 2 to player ${player}'s score");
        score += 2;
      }
    }
    if (allSameSuit && values.length == 5) {
      score += 5;
      debugPrint("Flush adding 5 to player ${player}'s score");
    }
    if (longestStraight == 5) {
      score += 5;
      debugPrint("Straight of 5 adding 5 to player ${player}'s score");
    } else if (longestStraight == 4) {
      score += 4;
      debugPrint("Straight of 4 adding 4 to player ${player}'s score");
      if (dupes) {
        score += 4;
        debugPrint("Second Straight of 4 adding 4 to player ${player}'s score");
      }
    } else if (longestStraight == 3) {
      score += 3;
      debugPrint("Straight of 3 adding 3 to player ${player}'s score");
      if (dupes) {
        score += 3;
        debugPrint("Second Straight of 3 adding 3 to player ${player}'s score");
      }
    }
    return score;
  }

  void updateScores() {
    // Player 1 find the score in the rows
    _scores = [0,0];
    for (int i = 0; i < 5; i++) {
      _scores[0] += findLineScore(currentGrid[i],1);
    }
    // Player 2 find the score in the columns
    for (int i = 0; i < 5; i++) {
      _scores[1] += findLineScore(currentGrid.map((row) => row[i]).toList(),2);
    }
  }

  int calculateComputerMove() {
    int bestMove = -1;
    int bestScore = -1;

    if (cardsState[25].isEmpty) {
      return 0; // No card to play
    }
    final topCard = cardsState[25].last;

    // Iterate over all 25 possible positions on the grid
    for (int i = 0; i < 25; i++) {
      // Check if the spot is empty
      if (cardsState[i].isEmpty) {
        // This is a potential move. Build what the column would look like.
        int colIndex = i % 5;
        List<SuitedCard?> potentialColumn = [];

        // Iterate through the rows of that column to build the list of cards
        for (int j = 0; j < 5; j++) {
          int cellIndexInColumn = j * 5 + colIndex;
          if (cellIndexInColumn == i) {
            potentialColumn.add(topCard);
          } else if (cardsState[cellIndexInColumn].isNotEmpty) {
            potentialColumn.add(cardsState[cellIndexInColumn].first);
          } else {
            potentialColumn.add(null);
          }
        }

        // Score the potential column for Player 2
        int score = findLineScore(potentialColumn, 2);

        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }

    // If no scoring move was found, find the first available empty spot as a fallback.
    if (bestMove == -1) {
      for (int i = 0; i < 25; i++) {
        if (cardsState[i].isEmpty) {
          bestMove = i;
          break;
        }
      }
    }
    return bestMove;
  }

  void runComputerTurn() {
    int move = calculateComputerMove();
    if (move == -1) {
      setState((){
        runFinishedGameState();
      });
      return;
    }
    final newCards = [...cardsState];
    final deck = [...newCards[25]];

    if (deck.isEmpty) return; // No more cards to play

    final topCard = deck.removeLast();
    newCards[25] = deck;
    final gridCell = [...newCards[move]];
    gridCell.add(topCard);
    newCards[move] = gridCell;

    setState(() {
      cardsState = newCards;
      currentGrid[move ~/ 5][move % 5] = topCard;
      playerTurn = 1;
      updateScores();
    });
  }

  void runFinishedGameState(){
    if (currentGrid.contains(null)) {
      return;
    }
    setState((){
      debugPrint("Game Over!");
      _gameFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool smallScreen = MediaQuery.sizeOf(context).width < 700;
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: CardGame<SuitedCard, int>(
          style: deckCardStyle(sizeMultiplier: smallScreen ? 0.8 : 1),
          children: [
            Padding(
                padding: EdgeInsetsGeometry.only(top: 10, left: 20, right: 20, bottom: MediaQuery.sizeOf(context).height * 0.2),
                child: Column(
                  mainAxisAlignment: smallScreen
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (rowIndex) {
                    return Expanded(
                      child: Row(
                        mainAxisAlignment: smallScreen
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (colIndex) {
                          final index = rowIndex * 5 + colIndex;
                          final states = cardsState[index];
                          return Expanded(
                            child: CardColumn<SuitedCard, int>(
                            value: index,
                            values: states,
                            maxGrabStackSize: 1,
                            canMoveCardHere: (move) {
                              return states.isEmpty;
                            },
                            onCardMovedHere: (move) {
                              setState(() {
                                final newCards = [...cardsState];
                                newCards[move.fromGroupValue].removeLast();
                                newCards[index].add(move.cardValues.first);
                                cardsState = newCards;
                                currentGrid[rowIndex][colIndex] = move.cardValues.first;
                                if (playerTurn == 1) {
                                  playerTurn = 2;
                                  runComputerTurn();
                                } else {
                                  playerTurn = 1;
                                }
                                updateScores();
                              });
                            },
                        ));
                      }),
                    ));
                  }),
            )),
            // The deck
            Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                    padding: EdgeInsetsGeometry.all(10),
                    child: CardDeck<SuitedCard, int>(
                      value: 25,
                      values: cardsState[25],
                      canGrab: playerTurn == 1,
                ))),
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                    padding: EdgeInsetsGeometry.only(bottom: 15),
                    child: Scoreboard(
                        numberOfPlayers: playerCount,
                        scores: _scores, activePlayer:
                    playerTurn, gameFinishedWinningPlayer:
                    _gameFinished
                      ? (_scores[0]>_scores[1])
                        ? 1
                        : 2
                      : null)))
          ],
        )),
        floatingActionButton: FloatingActionButton(
          onPressed: ()=>newGameDialog(context),
          tooltip: 'New Game',
          child: const Icon(Icons.add),
        ),
      );
  }
}

class Scoreboard extends StatelessWidget {
  final int numberOfPlayers;
  final List<int> scores;
  final int activePlayer;
  final int? gameFinishedWinningPlayer;
  final bool smallScreen;

  const Scoreboard({
    super.key,
    required this.numberOfPlayers,
    required this.scores,
    required this.activePlayer,
    this.gameFinishedWinningPlayer,
    this.smallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle activePlayerStyle = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.bold);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text((gameFinishedWinningPlayer!=null)
            ?"Player $gameFinishedWinningPlayer wins!"
            :"Scores:",
            style: (gameFinishedWinningPlayer!=null)
                ? activePlayerStyle
                : null),
        Text("You (rows):    ${scores[0]}",
            style: ((activePlayer == 1 && !(gameFinishedWinningPlayer == 2))
                || gameFinishedWinningPlayer == 1)
                ? activePlayerStyle
                : null
        ),
        Text("Bot (columns): ${scores[1]}",
            style: ((activePlayer == 2 && !(gameFinishedWinningPlayer == 1))
                || gameFinishedWinningPlayer == 2)
                ? activePlayerStyle
                : null
        ),
      ],
    );

  }

}



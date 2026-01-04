import 'package:flutter/foundation.dart';
import 'player.dart';

enum TurnPhase { waitingToStart, inProgress, waitingForNext }

class GameState extends ChangeNotifier {
  List<Player> players;
  int currentPlayerIndex;
  String selectedMode;
  int timerDuration;
  TurnPhase turnPhase;

  GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    required this.selectedMode,
    required this.timerDuration,
    this.turnPhase = TurnPhase.waitingToStart,
  });

  Player get currentPlayer => players[currentPlayerIndex];

  void startTurn() {
    turnPhase = TurnPhase.inProgress;
    notifyListeners();
  }

  void endTurn() {
    turnPhase = TurnPhase.waitingForNext;
    notifyListeners();
  }

  void nextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    turnPhase = TurnPhase.waitingToStart;
    notifyListeners();
  }
}
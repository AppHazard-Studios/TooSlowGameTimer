class GameConstants {
  static const List<String> modes = [
    'Chill',
    'Banter',
    'Savage',
    'Pirate',
    'Corporate',
  ];

  static const Map<String, List<String>> roastTemplates = {
    'Chill': [
      'Come on {name}, tick tock!',
      'Hey {name}, whenever you\'re ready!',
      '{name}, we\'re all waiting here!',
      'Take your time {name}... or don\'t!',
    ],
    'Banter': [
      'Oi {name}, my granny\'s faster than you!',
      '{name}, we\'re growing old here!',
      'Seriously {name}? We haven\'t got all day!',
      '{name}, speed it up mate!',
      'Come on {name}, what are you doing?',
    ],
    'Savage': [
      '{name}, you\'re slower than a wet week!',
      'Absolute joke {name}, hurry up!',
      '{name}, we could\'ve played three games by now!',
      'Pathetic {name}, let\'s go!',
      '{name}, are you even awake?',
    ],
    'Pirate': [
      'Arrr {name}, ye be holdin\' up the crew!',
      'Avast {name}, the tide waits for no one!',
      'Shiver me timbers {name}, make haste!',
      '{name}, ye scurvy dog, move it!',
    ],
    'Corporate': [
      '{name}, let\'s synergize with urgency please',
      '{name}, we need to action this immediately',
      'Time is money {name}, let\'s circle back to the game',
      '{name}, your bandwidth seems low today',
    ],
  };

  static const int defaultTimerSeconds = 10;
  static const int minTimerSeconds = 5;
  static const int maxTimerSeconds = 30;
}
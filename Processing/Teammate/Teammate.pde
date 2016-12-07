import processing.net.*;

static final boolean DEBUG = true;

static final int PLAYER1_START_X= 340;
static final int PLAYER1_START_Y = 100;
static final int PLAYER1_START_DIRECTION = 2;

static final int PLAYER2_START_X = 30; //opponent
static final int PLAYER2_START_Y = 175;
static final int PLAYER2_START_DIRECTION = 3;

static final int PLAYER3_START_X = 340; //teammate
static final int PLAYER3_START_Y = 300;
static final int PLAYER3_START_DIRECTION = 2;

static final int WINDOW_HEIGHT = 400;
static final int WINDOW_WIDTH = 400;
static final int WINDOW_X = 50;
static final int WINDOW_Y = 50;

processing.net.Client c;
String input;
int data[];

Player player;
Player teammate;
Player opponent;

boolean gameOver = false;
boolean waiting = false;
boolean winner;
boolean restart = false;

boolean postGame = false;

void setup() {
  size(500, 500);
  background(255);
  stroke(255, 0, 0);
  fill(255, 0, 0);

  teammate = new Player(PLAYER1_START_X + WINDOW_X, PLAYER1_START_Y + WINDOW_Y, PLAYER1_START_DIRECTION, false, true);
  player = new Player(PLAYER3_START_X + WINDOW_X, PLAYER3_START_Y + WINDOW_Y, PLAYER3_START_DIRECTION, false, false);

  opponent = new Player(PLAYER2_START_X + WINDOW_X, PLAYER2_START_Y + WINDOW_Y, PLAYER2_START_DIRECTION, true, false);

  player.setOpponent(opponent);
  teammate.setOpponent(opponent);

  //    opponent.setOpponent(player); // will need to update
  opponent.setOpponent(player, teammate);

  c = new processing.net.Client(this, "127.0.0.1", 12345);
}

void draw() {
  //  clear();
  background(0);  
  pushStyle();
  noFill();
  stroke(255, 0, 0);
  rect(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT);
  popStyle();

  stroke(125);
  fill(125);
  //send info to server
  player.renderFlare();
  teammate.renderFlare();
  player.render();
  //recieve info from server/opponent here
  if (c.available() > 0) {
    try {
      input = c.readString();
      input = input.substring(0, input.indexOf("\n")); // only up to the newline
      data = int(split(input, ' ')); // split values into an array
      if (DEBUG) println("data.length: " + data.length);
      if (data.length > 2) {
        if (data[0] == 1) opponent.clientUpdate(data);
        else if (data[0] == 2) teammate.clientUpdate(data); //do something
        else if (data[0] == 3) println("hey");
      } else { 
        if (data[0] == 1) opponent.restart();
        else if (data[0] == 2) teammate.restart();
      }
    }
    catch(StringIndexOutOfBoundsException e) {
      //      if (DEBUG) println(input); //something went wrong
      tryAgain(input);
    }

    //draw information from server
  }

  opponent.render();

  teammate.render();

  if (gameOver) {
    stroke(0);

    if (waiting) {
      text("Waiting on players", 15, 45);
      if (opponent.restart && teammate.restart)
      {
        reset();
      }
    } else {
      if (winner) text("You win. Press S to get ready for the next game", 15, 45);
      else text("You lose. Press S to get ready for the next game", 15, 45);
    }
  }
}

void tryAgain(String d) {
  int brap[] = int(split(input, ' '));
  if (brap.length > 1) { 
    if (brap[0] == 1) opponent.clientUpdate(brap);
    else if (brap[0] == 3) {
    } //teammate.clientUpdate(data); //do something
    else if (brap[0] == 2) teammate.clientUpdate(brap);
  } else {
    if (brap[0] == 1) opponent.restart();
    else if (brap[0] == 2) teammate.restart();
  }
  //  for(int i = 0; i < 10; i++) println(brap[i]);
}

void reset() {
  waiting = false;
  gameOver = false;
  player.reset();
  opponent.reset();
  teammate.reset();
  //sendData();
}

void keyPressed() {
  if (keyCode == UP) { //0    
    player.update(0);
  }
  if (keyCode == DOWN) {//1
    player.update(1);
  }
  if (keyCode == LEFT) {//2
    player.update(2);
  }
  if (keyCode == RIGHT) {//3
    player.update(3);
  }
  if (key == ' ' && gameOver == false && waiting == false) {
    player.update(9);
  }
  if ((key == 's' || key == 'S') && gameOver == true) { //we readied up
    player.restart();
    c.write("3\n"); //inform other players we are ready
    if (!opponent.restart || !teammate.restart) waiting = true; //we are waiting for players
    else reset();
  }
  if ((key == 'z' || key == 'Z') && gameOver == false && waiting == false) {
    //throwFlare
    player.update(8);
  }

  if (!gameOver && !waiting) sendData();
}

void sendData() {
  c.write(player.getData());
}
import processing.net.*;

static final boolean DEBUG = true;

static final int PLAYER1_START_X= 30;
static final int PLAYER1_START_Y = 175;
static final int PLAYER1_START_DIRECTION = 3;

static final int PLAYER2_START_X = 340;
static final int PLAYER2_START_Y = 100;
static final int PLAYER2_START_DIRECTION = 2;

static final int PLAYER3_START_X = 340; //teammate
static final int PLAYER3_START_Y = 300;
static final int PLAYER3_START_DIRECTION = 2;

static final int WINDOW_HEIGHT = 400;
static final int WINDOW_WIDTH = 400;
static final int WINDOW_X = 50;
static final int WINDOW_Y = 50;

processing.net.Server s;
Client c;
String input;
int data[];

Player player;
Player gunner;
Player healer;

boolean gameOver = false;
boolean waiting = false;
boolean winner;

void setup() {
  size(500, 500);
  background(255);
  stroke(255, 0, 0);
  fill(255, 0, 0);
  textFont(createFont("SanSerif", 16));

  player = new Player(PLAYER1_START_X + WINDOW_X, PLAYER1_START_Y + WINDOW_Y, PLAYER1_START_DIRECTION, true, false);
  gunner = new Player(PLAYER2_START_X + WINDOW_X, PLAYER2_START_Y + WINDOW_Y, PLAYER2_START_DIRECTION, false, false);
  healer = new Player(PLAYER3_START_X + WINDOW_X, PLAYER3_START_Y + WINDOW_Y, PLAYER3_START_DIRECTION, false, true);

  //  player.setOpponent(gunner);
  player.setOpponent(gunner, healer);

  gunner.setOpponent(player);
  healer.setOpponent(player);
  s = new processing.net.Server(this, 12345);
}

void draw() {
  //  clear();
  background(255);  
  pushStyle();
  noFill();
  stroke(255, 0, 0);
  rect(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT);
  popStyle();

  stroke(255, 0, 0);
  fill(255, 0, 0);
  //send player information to opponent
  player.render();

  //recieve info from client/opponent here
  c = s.available();
  if (c != null) {
    try {
      input = c.readString();
      input = input.substring(0, input.indexOf("\n")); // only up to the newline
      data = int(split(input, ' ')); // split values into an array
      if (DEBUG) println("data.length: " + data.length);
      if (data.length > 1) {
        if (data[0] == 2) {
          gunner.clientUpdate(data);
          sendData(input);
        } else if (data[0] == 3) {
          healer.clientUpdate(data);
          sendData(input);
          //sendData(input);
        }
      } else {
        if (data[0] == 2) {
          gunner.restart();
          sendData(input);
        } else if (data[0] == 3) {
          println(data[0] + "                    " + millis());
          healer.restart();
          sendData(input);
        }
      }
    }
    catch(StringIndexOutOfBoundsException e) {
      if (DEBUG) println("woops"); //something went wrong
    }
    //draw information from client
  }

  stroke(0, 0, 255);
  fill(0, 0, 255);
  gunner.render();
  healer.render();

  if (gameOver) {
    stroke(0);

    if (waiting) {
      text("Waiting on players", 15, 45);
      if (gunner.restart && healer.restart)
      {
        reset();
      }
    } else {
      if (winner) text("You win. Press S to get ready for the next game", 15, 45);
      else text("You lose. Press S to get ready for the next game", 15, 45);
    }
  }
}

void reset() {
  waiting = false;
  gameOver = false;
  player.reset();
  gunner.reset();
  healer.reset();
//  sendData();
}

void keyPressed() {
  //  if (!gameOver) {
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
  if (key == 's' && gameOver == true) {
    player.restart();
    s.write("1\n"); //inform other players we are ready
    if (!gunner.restart || !healer.restart) waiting = true;
    else reset();
  }
  if (key == 'z' && gameOver == false && waiting == false) {
    //throwFlare
    player.update(8);
  }

  if (!gameOver && !waiting) sendData();
}

void sendData() {
  s.write(player.getData());
}

void sendData(String d) {
  s.write(d);
}
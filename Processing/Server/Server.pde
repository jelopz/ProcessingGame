import processing.net.*;

static final boolean DEBUG = true;

int windowHeight = 400;
int windowWidth = 400;

processing.net.Server s;
Client c;
String input;
int data[];

Player player;
Player gunner;
Player healer;

int startX = 30;
int startY = 150;
int startDirection = 3;

int gunnerStartX = 340 + 15;
int gunnerStartY = 150 + 15;
int gunnerStartDirection = 2;

int healerStartX;
int healerStartY;
int healerStartDirection;

boolean gameOver = false;
boolean waiting = false;
boolean winner;

void setup() {
  size(400, 400);
  background(255);
  stroke(255, 0, 0);
  fill(255, 0, 0);
  textFont(createFont("SanSerif", 16));

  player = new Player(startX, startY, startDirection, true);
  gunner = new Player(gunnerStartX, gunnerStartY, gunnerStartDirection, false);
  player.setOpponent(gunner);
  gunner.setOpponent(player);
  s = new processing.net.Server(this, 12345);
}

void draw() {
  //  clear();
  background(255);  

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
      if(DEBUG) println("data.length: " + data.length);
      if (data.length > 1) gunner.clientUpdate(data);
      else gunner.restart();
    }
    catch(StringIndexOutOfBoundsException e) {
      if(DEBUG) println("woops"); //something went wrong
    }
    //draw information from client
  }

  stroke(0, 0, 255);
  fill(0, 0, 255);
  gunner.render();

  if (gameOver) {
    stroke(0);

    if (waiting) {
      text("Waiting on opponent", 15, 45);
      if (gunner.restart)
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
  player.reset(0);
  gunner.reset(1);
  sendData();
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
    if (!gunner.restart) waiting = true;
    else reset();
  }

  if (!gameOver && !waiting) sendData();
}

void sendData() {
  s.write(player.getData());
}
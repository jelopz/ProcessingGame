import processing.net.*;

int windowHeight = 400;
int windowWidth = 400;

processing.net.Client c;
String input;
int data[];

Player player;
Player opponent;

int startX = 340 + 15;
int startY = 150 + 15;
int startDirection = 2;
int opponentStartX = 30;
int opponentStartY = 150;
int opponentStartDirection = 3;

boolean gameOver = false;
boolean waiting = false;
boolean winner;
boolean restart = false;

boolean postGame = false;

void setup() {
  size(400, 400);
  background(255);
  stroke(255, 0, 0);
  fill(255, 0, 0);

  player = new Player(startX, startY, startDirection, false);
  opponent = new Player(opponentStartX, opponentStartY, opponentStartDirection, true);
  player.setOpponent(opponent);
  opponent.setOpponent(player);

  c = new processing.net.Client(this, "127.0.0.1", 12345);
}

void draw() {
  //  clear();
  background(0);  

  stroke(125);
  fill(125);
  //send info to server
  player.render(0);
  //recieve info from server/opponent here
  if (c.available() > 0) {
    try {
      input = c.readString();
      input = input.substring(0, input.indexOf("\n")); // only up to the newline
      data = int(split(input, ' ')); // split values into an array
      println("data.length: " + data.length);
      if (data.length > 1) opponent.clientUpdate(data);
      else opponent.restart();
    }
    catch(StringIndexOutOfBoundsException e) {
      println("woops"); //something went wrong
    }

    //draw information from server
  }

  opponent.render(1);

  if (gameOver) {
    stroke(0);

    if (waiting) {
      text("Waiting on opponent", 15, 45);
      if (opponent.restart)
      {
        reset();
      }
    } else {
      if (winner) text("You win. Press S to get ready for the next game", 15, 45);
      else text("You lose. Press S to get ready for the next game", 15, 45);
    }
  }

  //println("Health: " + player.health);
  //println("Opp Health: " + opponent.health);
}

//void restart() {
//  player = new Player(startX, startY, startDirection, true);
//  opponent = new Player(opponentStartX, opponentStartY, opponentStartDirection, false);
//  player.setOpponent(opponent);
//  opponent.setOpponent(player);
//  gameOver = false;
//}

void reset() {
  waiting = false;
  gameOver = false;
  player.reset(0);
  opponent.reset(1);
  sendData();
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
  if (key == 's' && gameOver == true) { //we readied up
    player.restart();
    c.write("1\n"); //inform other players we are ready
    if (!opponent.restart) waiting = true; //we are waiting for players
    else reset();
  }

  if (!gameOver && !waiting) sendData();
}

void sendData() {
  c.write(player.x + " " + player.y + " " + player.direction + " " + player.projectileStartX + " " + player.projectileStartY + " " +
    player.projectileEndX + " " + player.projectileEndY + " " + player.shotFired + " " + player.projectileDirection + "\n");
}
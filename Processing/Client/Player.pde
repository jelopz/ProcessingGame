public class Player {


  Player opponentMan;
  private final int boxW = 30;
  private int health;
  private int x, y;
  private int direction;
  private int projectileDirection;
  private int projectileStartX, projectileStartY;
  private int projectileEndX, projectileEndY;
  private int shotFired;
  private boolean soundPulsing;
  private int pulseCenterX;
  private int pulseCenterY;
  private int pulseEllipseD;
  private int hits;
  
  private boolean restart = false;
  private boolean ready;

  public Player(int x, int y, int direction, boolean playable) {
    this.x = x;
    this.y = y;
    this.direction = direction;
    health = 3;
    hits = 0;
  }

  private void render(int player) { //parameter is 0 if drawing player, 1 if drawing opponent
    //    println(player + " health " + health);
    if (!(player == 1)) drawBox();
    if(!gameOver) drawShot(player);
    if (soundPulsing) drawSound();
  }

  private void drawSound() {
    stroke(255,255,0);
    noFill();
    ellipse(pulseCenterX, pulseCenterY, pulseEllipseD, pulseEllipseD);
    pulseEllipseD += 25;
  }

  private void drawShot(int player) {
    if (shotFired == 1) {
      if (!soundPulsing) {
        pulseCenterX = projectileStartX;
        pulseCenterY = projectileStartY;
        pulseEllipseD = 5;
        soundPulsing = true;
      }
      if (!(player == 1)) line(projectileStartX, projectileStartY, projectileEndX, projectileEndY);
      switch(projectileDirection) {
      case 0://up
        projectileStartX = projectileEndX;
        projectileStartY = projectileEndY;
        projectileEndY -= 5;
        break;
      case 1://down
        projectileStartX = projectileEndX;
        projectileStartY = projectileEndY;
        projectileEndY += 5;
        break;
      case 2://left
        projectileStartX = projectileEndX;
        projectileStartY = projectileEndY;
        projectileEndX -= 5;
        break;
      case 3://right
        projectileStartX = projectileEndX;
        projectileStartY = projectileEndY;
        projectileEndX += 5;
        break;
      default:
        break;
      }
    }

    if (projectileStartX <= opponentMan.x+boxW && projectileStartX >= opponentMan.x) {
      if (projectileStartY <= opponentMan.y+boxW && projectileStartY >= opponentMan.y) {
        shotFired = 0;
        soundPulsing = false;
        if (player == 0) {
          println("You hit the enemy");
          println("You win");
          gameOver = true;
          winner = true;
          opponentMan.hits = 0;
        } else {
          hits++;
          println("You've been hit " + hits + " time(s)");
          if (hits == 3){
            println("You lose");
            gameOver = true;
            winner = false;
            hits = 0;
          }
        }
        projectileStartX = -5;
        projectileStartY = -5;
        projectileEndX = -5;
        projectileEndY = -5;
      }
    }
    if (projectileStartX <= 0 || projectileStartX >= windowWidth) {
      shotFired = 0;
      soundPulsing = false;
    }
    if (projectileStartY <= 0 || projectileStartY >= windowHeight) {
      shotFired = 0;
      soundPulsing = false;
    }
  }

  private void drawBox() {
    rect(x, y, boxW, boxW);

    switch(direction) {
    case 0://up
      line(x+boxW/2, y, x+boxW/2, y-5);
      break;
    case 1://down
      line(x+boxW/2, y+boxW, x+boxW/2, y+boxW+5);
      break;
    case 2://left
      line(x, y+boxW/2, x-5, y+boxW/2);
      break;
    case 3://right
      line(x+boxW, y+boxW/2, x+boxW+5, y+boxW/2);
      break;
    default:
      break;
    }
  }

  private void update(int movementDirection) {
    if (movementDirection != 9) {
      move(movementDirection);
    } else updateShot();
  }

  private void clientUpdate(int data[]) {
    try {
      x = data[0];
      y = data[1];
      direction = data[2];
      projectileStartX = data[3];
      projectileStartY = data[4];
      projectileEndX = data[5];
      projectileEndY = data[6];
      shotFired = data[7];
      projectileDirection = data[8];
//      restart = data[9];
      //health = data[9];
      //opponent.health = data[10];
    }
    catch(ArrayIndexOutOfBoundsException e) {
      println("ArrayIndexOutOfBoundsException");
    }
  }

  private void move(int movementDirection) {
    boolean isLegal = true;

    if (movementDirection == 0) {
      if (y == opponentMan.y+boxW) {
        if ((x >= opponentMan.x && x < opponentMan.x+boxW) || (x+boxW>opponentMan.x && x+boxW<=opponentMan.x+boxW)) {
          isLegal = false;
        }
      }

      if (isLegal && y != 0) y-=5;

      direction = 0;
    } else if (movementDirection == 1) {
      if (y+boxW == opponentMan.y) {
        if ((x >= opponentMan.x && x < opponentMan.x+boxW) || (x+boxW>opponentMan.x && x+boxW<=opponentMan.x+boxW)) {
          isLegal = false;
        }
      }
      if (isLegal && y != (windowHeight - boxW)) y+=5;
      direction = 1;
    } else if (movementDirection == 2) {
      if (x == opponentMan.x+boxW) {
        if ((y >= opponentMan.y && y < opponentMan.y+boxW) || (y+boxW>opponentMan.y && y+boxW <= opponentMan.y+boxW)) {
          isLegal = false;
        }
      }

      if (isLegal && x != 0) x-=5;
      direction = 2;
    } else if (movementDirection == 3) {
      if (x+boxW == opponentMan.x) {
        if ((y >= opponentMan.y && y < opponentMan.y+boxW) || (y+boxW>opponentMan.y && y+boxW <= opponentMan.y+boxW)) {
          isLegal = false;
        }
      }

      if (isLegal && x != windowWidth - boxW) x+=5;
      direction = 3;
    }
  }


  private void updateShot() {
    if (shotFired == 0) {
      switch(direction) {
      case 0://up
        projectileStartX = x+boxW/2;
        projectileStartY = y-5;
        projectileEndX = x+boxW/2;
        projectileEndY = y-10;
        projectileDirection = 0;
        shotFired = 1;
        break;
      case 1://down
        projectileStartX = x+boxW/2;
        projectileStartY = y+boxW+5;
        projectileEndX = x+boxW/2;
        projectileEndY = y+boxW+10;
        projectileDirection = 1;
        shotFired = 1;
        break;
      case 2://left
        projectileStartX = x-5;
        projectileStartY = y+boxW/2;
        projectileEndX = x-10;
        projectileEndY = y+boxW/2;
        projectileDirection = 2;
        shotFired = 1;
        break;
      case 3://right
        projectileStartX = x+boxW+5;
        projectileStartY = y+boxW/2;
        projectileEndX = x+boxW+10;
        projectileEndY = y+boxW/2;
        projectileDirection = 3;
        shotFired = 1;
        break;
      default:
        break;
      }
    }
  }

  private void setOpponent(Player opponent1) {
    this.opponentMan = opponent1;
  }
  
  public void restart(){
    this.restart = true;
  }
  
  public void reset(int player) {
    this.restart = false;
    if (player == 0) {
      x = startX;
      y = startY;
      direction = startDirection;
    }
    else
    {
      x = opponentStartX;
      y = opponentStartY;
      direction = opponentStartDirection;
    }
  }
}
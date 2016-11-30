public class Player {

  private final int BOX_W = 30;
  private final int ELLIPSE_W = 15;

  private final int FLARE_DURATION = 5;
  private final int FLARE_CD = 10;
  private final int FLARE_VISION_RANGE = 15;
  private final int FLARE_THROW_RANGE = 150;

  Player opponentMan;
  Player opponentTeam[] = new Player[2];

  private int playerW;
  private int health;
  private int x, y;
  private int direction;

  private int projectileDirection;
  private int projectileStartX, projectileStartY;
  private int projectileEndX, projectileEndY;
  private int shotFired;

  private int flareX, flareY;
  private int flareCD, flareMillis;

  private int hits;

  private boolean restart = false;

  private boolean isTeam;


  public Player(int x, int y, int direction, boolean isBox) {
    this.x = x;
    this.y = y;
    this.direction = direction;
    health = 3;
    hits = 0;

    flareCD = FLARE_CD*1000;

    if (isBox) {
      playerW = BOX_W;
      isTeam = false;
    } else {
      playerW = ELLIPSE_W;
      isTeam = true;
    }
    ellipseMode(CORNER);
  }

  private void render() { //parameter is 0 if drawing player, 1 if drawing opponent
    if (!isTeam) drawBox();
    else drawCircle();

    //update flare cds and handle flare accordingly
    if (flareCD < FLARE_CD*1000) flareCD = millis() - flareMillis;
    if (flareCD < (FLARE_CD - FLARE_DURATION)*1000) drawFlare();

    if (shotFired == 1) drawShot();

    if(DEBUG) println(flareCD);
  }

  private void updateShot() {
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

  private void checkShotCollisionForPlayers(Player opp) {
    if (projectileStartX <= opp.x+opp.playerW && projectileStartX >= opp.x) {
      if (projectileStartY <= opp.y+opp.playerW && projectileStartY >= opp.y) {
        shotFired = 0;
        if (!isTeam) {
          hits++;
          if (DEBUG) println("You hit the enemy " + hits + " time(s)");
          if (hits == 3) {
            if (DEBUG) println("You win");
            gameOver = true;
            winner = true;
            hits = 0;
          }
        } else {
          if (DEBUG) println("You've been hit");
          if (DEBUG) println("You lose");
          gameOver = true;
          winner = false;
          opp.hits = 0;
        }
        projectileStartX = -5;
        projectileStartY = -5;
        projectileEndX = -5;
        projectileEndY = -5;
      }
    }
  }

  private void checkShotCollisionForBoundaries() {
    if (projectileStartX <= 0 || projectileStartX >= windowWidth) {
      shotFired = 0;
      //      soundPulsing = false;
    }
    if (projectileStartY <= 0 || projectileStartY >= windowHeight) {
      shotFired = 0;
      //      soundPulsing = false;
    }
  }

  private void checkShotCollision() {
    //commented out code is end goal once team of 2 is implemented. As of now, it's still 1v1.
    //if (isTeam) checkShotCollisionForPlayers(opponentMan);
    //else {
    //  checkShotCollisionForPlayers(opponentTeam[0]);
    //  checkShotCollisionForPlayers(opponentTeam[1]);
    //}
    checkShotCollisionForPlayers(opponentMan);
    checkShotCollisionForBoundaries();
  }


  private void drawShot() {
    line(projectileStartX, projectileStartY, projectileEndX, projectileEndY);
    updateShot();   
    checkShotCollision();
  }

  private void drawFlare() {
    rectMode(RADIUS);
    stroke(0, 255, 0);
    noFill();
    rect(flareX, flareY, FLARE_VISION_RANGE, FLARE_VISION_RANGE);
    rectMode(CORNER);
  }

  private void drawBox() {
    rect(x, y, BOX_W, BOX_W);
    drawDirectionalIndicator();
  }

  private void drawCircle() {
    ellipse(x, y, ELLIPSE_W, ELLIPSE_W);
    drawDirectionalIndicator();
  }

  private void drawDirectionalIndicator() {
    switch(direction) {
    case 0://up
      line(x+playerW/2, y, x+playerW/2, y-5);
      break;
    case 1://down
      line(x+playerW/2, y+playerW, x+playerW/2, y+playerW+5);
      break;
    case 2://left
      line(x, y+playerW/2, x-5, y+playerW/2);
      break;
    case 3://right
      line(x+playerW, y+playerW/2, x+playerW+5, y+playerW/2);
      break;
    default:
      break;
    }
  }

  private void update(int movementDirection) {
    if (movementDirection < 5) {
      move(movementDirection);
    } else {
      switch(movementDirection) {
      case 8:
        throwFlare();
        break;
      case 9:
        playerShot();
        break;
      default:
        break;
      }
    }
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
      if (DEBUG) println("ArrayIndexOutOfBoundsException");
    }
  }


  private void move(int movementDirection) {
    boolean isLegal = true;

    if (movementDirection == 0) {
      if (y == opponentMan.y+opponentMan.playerW) {
        if ((x >= opponentMan.x && x < opponentMan.x+opponentMan.playerW) ||
          (x+playerW>opponentMan.x && x+playerW<=opponentMan.x+opponentMan.playerW) ||
          (x<opponentMan.x && x < opponentMan.x+opponentMan.playerW && x+playerW>opponentMan.x && x+playerW>opponentMan.x+opponentMan.playerW)) {
          isLegal = false;
        }
      }

      if (isLegal && y != 0) y-=5;

      direction = 0;
    } else if (movementDirection == 1) {
      if (y+playerW == opponentMan.y) {
        if ((x >= opponentMan.x && x < opponentMan.x+opponentMan.playerW) ||
          (x+playerW>opponentMan.x && x+playerW<=opponentMan.x+opponentMan.playerW) ||
          (x<opponentMan.x && x < opponentMan.x+opponentMan.playerW && x+playerW>opponentMan.x && x+playerW>opponentMan.x+opponentMan.playerW)) {
          isLegal = false;
        }
      }
      if (isLegal && y != (windowHeight - playerW)) y+=5;
      direction = 1;
    } else if (movementDirection == 2) {
      if (x == opponentMan.x+opponentMan.playerW) {
        if ((y >= opponentMan.y && y < opponentMan.y+opponentMan.playerW) ||
          (y+playerW>opponentMan.y && y+playerW <= opponentMan.y+opponentMan.playerW) ||
          (y<opponentMan.y && y < opponentMan.y+opponentMan.playerW && y+playerW>opponentMan.y && y+playerW>opponentMan.y+opponentMan.playerW)) {
          isLegal = false;
        }
      }

      if (isLegal && x != 0) x-=5;
      direction = 2;
    } else if (movementDirection == 3) {
      if (x+playerW == opponentMan.x) {
        if ((y >= opponentMan.y && y < opponentMan.y+opponentMan.playerW) ||
          (y+playerW>opponentMan.y && y+playerW <= opponentMan.y+opponentMan.playerW) ||
          (y<opponentMan.y && y < opponentMan.y+opponentMan.playerW && y+playerW>opponentMan.y && y+playerW>opponentMan.y+opponentMan.playerW)) {
          isLegal = false;
        }
      }

      if (isLegal && x != windowWidth - playerW) x+=5;
      direction = 3;
    }
  }

  private void throwFlare() {
    //case n:
    //determine flares ending location based on players position and direction they are facing

    //ref:
    //private final int FLARE_CD = 5;
    //private final int FLARE_VISION_RANGE = 20;
    //private final int FLARE_THROW_RANGE = 20;

    //private int flareX, flareY;
    //private int flareCD;

    if (flareCD >= FLARE_CD*1000) {
      switch(direction) {
      case 0: //up
        flareX = x + playerW/2;
        flareY = y + playerW/2 - FLARE_THROW_RANGE;
        break;
      case 1: //down
        flareX = x + playerW/2;
        flareY = y + playerW/2 + FLARE_THROW_RANGE;
        break;
      case 2: //left
        flareX = x + playerW/2 - FLARE_THROW_RANGE;
        flareY = y + playerW/2;
        break;
      case 3: //right
        flareX = x + playerW/2 + FLARE_THROW_RANGE;
        flareY = y + playerW/2;
        break;
      default:
        break;
      }

      flareCD = 0;
      flareMillis = millis();
    }
  }

  private void playerShot() {
    if (shotFired == 0) {
      switch(direction) {
      case 0://up
        projectileStartX = x+playerW/2;
        projectileStartY = y-5;
        projectileEndX = x+playerW/2;
        projectileEndY = y-10;
        projectileDirection = 0;
        shotFired = 1;
        break;
      case 1://down
        projectileStartX = x+playerW/2;
        projectileStartY = y+playerW+5;
        projectileEndX = x+playerW/2;
        projectileEndY = y+playerW+10;
        projectileDirection = 1;
        shotFired = 1;
        break;
      case 2://left
        projectileStartX = x-5;
        projectileStartY = y+playerW/2;
        projectileEndX = x-10;
        projectileEndY = y+playerW/2;
        projectileDirection = 2;
        shotFired = 1;
        break;
      case 3://right
        projectileStartX = x+playerW+5;
        projectileStartY = y+playerW/2;
        projectileEndX = x+playerW+10;
        projectileEndY = y+playerW/2;
        projectileDirection = 3;
        shotFired = 1;
        break;
      default:
        break;
      }
    }
  }

  public void setOpponent(Player opponent1) {
    this.opponentMan = opponent1;
  }

  public void setOpponent(Player o1, Player o2) {
    opponentTeam[0] = o1;
    opponentTeam[1] = o2;
  }

  public void restart() {
    this.restart = true;
  }

  public void reset(int player) {
    this.restart = false;
    if (player == 0) {
      x = startX;
      y = startY;
      direction = startDirection;
    } else
    {
      x = gunnerStartX;
      y = gunnerStartY;
      direction = gunnerStartDirection;
    }
  }

  public String getData() {
    return (x + " " + y + " " + direction + " " + projectileStartX + " " + projectileStartY + " " + projectileEndX + " " + projectileEndY + " " + shotFired + " " + projectileDirection + "\n");
  }
}
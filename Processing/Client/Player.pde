public class Player {

  private final int BOX_W = 30;
  private final int ELLIPSE_W = 15;

  private final int FLARE_DURATION = 5;
  private final int FLARE_CD = 10;
  private final int FLARE_VISION_RANGE = 60;
  private final int FLARE_THROW_RANGE = 125;

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
  private boolean flareActive;

  private boolean nwRevealed, neRevealed, swRevealed, seRevealed;
  private int[] visiblePoints = new int[8];

  private boolean soundPulsing;
  private int pulseCenterX;
  private int pulseCenterY;
  private int pulseEllipseD;

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
    flareActive = false;

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
    //update flare cds and handle flare accordingly
    if (flareCD < FLARE_CD*1000) {
      flareCD = millis() - flareMillis;
      if (flareCD < (FLARE_CD - FLARE_DURATION)*1000) {
        flareActive = true;
        drawFlare();
      } else flareActive = false;
    }

    if (opponentMan.flareActive && !isTeam && isRevealed(opponentMan)) {
      //determineVisibleBoxCoordinates()
      //drawVisibleBoxCoordinates()
      drawBox();
    }

    //    println(player + " health " + health);
    if (isTeam) drawCircle();

    if (shotFired == 1) drawShot();
    if (soundPulsing) drawSound();
  }

  private void determineVisibleEnemyCoordinates() {
    //set S: nw, ne, sw, se
    //set C: (nw)1, (ne)1, (sw)1, (se)1, (nw, ne)1, (nw, sw)1, (sw, se)1, (ne, se)1, (nw, ne, sw, se)1
    //set C is all the legal combinations of set S. Size 9

    if (nwRevealed) {
      if (neRevealed) {
        if (swRevealed) { //(nw, ne, sw, se) draw whole box
          visiblePoints[0] = x;
          visiblePoints[1] = y;

          visiblePoints[2] = x+playerW;
          visiblePoints[3] = y;

          visiblePoints[4] = x;
          visiblePoints[5] = y+playerW;

          visiblePoints[6] = x+playerW;
          visiblePoints[7] = y+playerW;
        } else { //(nw, ne) only top two corners are visible. bottom is outside flare aoe
          visiblePoints[0] = x;
          visiblePoints[1] = y;

          visiblePoints[2] = x+playerW;
          visiblePoints[3] = y;

          visiblePoints[4] = x;
          visiblePoints[5] = flareY + FLARE_VISION_RANGE;

          visiblePoints[6] = x+playerW;
          visiblePoints[7] = flareY + FLARE_VISION_RANGE;
        }
      } else if (swRevealed) { //(nw, sw) only left two corners are visible. right of flare.
          visiblePoints[0] = x;
          visiblePoints[1] = y;

          visiblePoints[2] = flareX + FLARE_VISION_RANGE;
          visiblePoints[3] = y;

          visiblePoints[4] = x;
          visiblePoints[5] = y+playerW;

          visiblePoints[6] = flareX + FLARE_VISION_RANGE;
          visiblePoints[7] = y + playerW;
      } else //(nw) //only the top left corner is visible. bottom right of flare
      {
          visiblePoints[0] = x;
          visiblePoints[1] = y;

          visiblePoints[2] = flareX + FLARE_VISION_RANGE;
          visiblePoints[3] = y;

          visiblePoints[4] = x;
          visiblePoints[5] = flareY + FLARE_VISION_RANGE;

          visiblePoints[6] = flareX + FLARE_VISION_RANGE;
          visiblePoints[7] = flareY + FLARE_VISION_RANGE;
      }
    } else if (neRevealed) {
      if (seRevealed) { //(ne, se) only right two corners are visible. left of flare
          visiblePoints[0] = flareX;
          visiblePoints[1] = y;

          visiblePoints[2] = x + playerW;
          visiblePoints[3] = y;

          visiblePoints[4] = flareX;
          visiblePoints[5] = y + playerW;

          visiblePoints[6] = x + playerW;
          visiblePoints[7] = y + playerW;
      } else { //(ne) top left corner is visible. bottom left of flare
          visiblePoints[0] = flareX;
          visiblePoints[1] = y;

          visiblePoints[2] = x + playerW;
          visiblePoints[3] = y;

          visiblePoints[4] = flareX;
          visiblePoints[5] = flareY + FLARE_VISION_RANGE;

          visiblePoints[6] = x + playerW;
          visiblePoints[7] = flareY + FLARE_VISION_RANGE;
      }
    } else if (swRevealed) {
      if (seRevealed) { //(sw, se) bottom two corners are visible. top of flare
          visiblePoints[0] = x;
          visiblePoints[1] = flareY;

          visiblePoints[2] = x + playerW;
          visiblePoints[3] = flareY;

          visiblePoints[4] = x;
          visiblePoints[5] = y + playerW;

          visiblePoints[6] = x + playerW;
          visiblePoints[7] = y + playerW;
      } else { //(sw) //bottom left corner is visible. top right of flare
          visiblePoints[0] = x;
          visiblePoints[1] = flareY;

          visiblePoints[2] = flareX + FLARE_VISION_RANGE;
          visiblePoints[3] = flareY;

          visiblePoints[4] = x;
          visiblePoints[5] = y + playerW;

          visiblePoints[6] = flareX + FLARE_VISION_RANGE;
          visiblePoints[7] = y + playerW;
      }
    } else { //(se) bottom right corner is visible. top left of flare
          visiblePoints[0] = flareX;
          visiblePoints[1] = flareY;

          visiblePoints[2] = x + playerW;
          visiblePoints[3] = flareY;

          visiblePoints[4] = flareX;
          visiblePoints[5] = y + playerW;

          visiblePoints[6] = x + playerW;
          visiblePoints[7] = y + playerW;
    }
  }

  private boolean isRevealed(Player opp) {
    nwRevealed = isPointInFlare(opp, x, y);
    neRevealed = isPointInFlare(opp, x+playerW, y);
    swRevealed = isPointInFlare(opp, x, y+playerW);
    seRevealed = isPointInFlare(opp, x+playerW, y+playerW);

    if (nwRevealed || neRevealed || swRevealed || seRevealed) return true;
    else return false;
  }

  private boolean isPointInFlare(Player opp, int px, int py) {
    if (px >= opp.flareX && px <= opp.flareX+FLARE_VISION_RANGE &&
      py >= opp.flareY && py <= opp.flareY+FLARE_VISION_RANGE) return true;
    else return false;
  }

  private void drawFlare() {
    pushStyle();
    rectMode(CORNER);
    stroke(235, 116, 19);
    fill(235, 116, 19);
    rect(flareX, flareY, FLARE_VISION_RANGE, FLARE_VISION_RANGE);
    popStyle();
  }

  private void drawSound() {
    ellipseMode(CENTER);
    stroke(255, 255, 0);
    noFill();
    ellipse(pulseCenterX, pulseCenterY, pulseEllipseD, pulseEllipseD);
    pulseEllipseD += 25;
    ellipseMode(CORNER);
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
        soundPulsing = false;
        if (isTeam) {
          if (DEBUG) println("You hit the enemy");
          if (DEBUG) println("You win");
          gameOver = true;
          winner = true;
          opponentMan.hits = 0;
        } else {
          hits++;
          if (DEBUG) println("You've been hit " + hits + " time(s)");
          if (hits == 3) {
            if (DEBUG) println("You lose");
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
  }

  private void checkShotCollisionForBoundaries() {
    if (projectileStartX <= 0 || projectileStartX >= windowWidth) {
      shotFired = 0;
      soundPulsing = false;
    }
    if (projectileStartY <= 0 || projectileStartY >= windowHeight) {
      shotFired = 0;
      soundPulsing = false;
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
    if (!soundPulsing) {
      pulseCenterX = projectileStartX;
      pulseCenterY = projectileStartY;
      pulseEllipseD = 5;
      soundPulsing = true;
    }

    if (isTeam) line(projectileStartX, projectileStartY, projectileEndX, projectileEndY);
    updateShot();
    checkShotCollision();
  }

  private void drawBox() {
    pushStyle();
    noStroke();
    fill(255, 0, 0);
    rect(x, y, BOX_W, BOX_W);
    drawDirectionalIndicator();
    popStyle();
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
        flareX = x - 15;
        flareY = y - FLARE_THROW_RANGE;
        break;
      case 1: //down
        flareX = x - 15;
        flareY = y + FLARE_THROW_RANGE;
        break;
      case 2: //left
        flareX = x - FLARE_THROW_RANGE;
        flareY = y - 15;
        break;
      case 3: //right
        flareX = x + FLARE_THROW_RANGE;
        flareY = y - 15;
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

  private void setOpponent(Player opponent1) {
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
      x = opponentStartX;
      y = opponentStartY;
      direction = opponentStartDirection;
    }
  }

  public String getData() {
    return (x + " " + y + " " + direction + " " + projectileStartX + " " + projectileStartY + " " + projectileEndX + " " + projectileEndY + " " + shotFired + " " + projectileDirection + "\n");
  }
}

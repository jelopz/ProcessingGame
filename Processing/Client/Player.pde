public class Player {

  private final int BOX_W = 30;
  private final int ELLIPSE_W = 15;

  private final int FLARE_DURATION = 5;
  private final int FLARE_CD = 10;
  private final int FLARE_VISION_RANGE = 60;
  private final int FLARE_THROW_RANGE = 125;
  private final int FLARE_CAST_TIME = 1;
  private final int FLARE_PROJECTILE_BASE_SIZE = 1;
  private final int FLARE_PROJECTILE_SPEED = 2;

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

  private int flareProjectileDirection;
  private int flareProjectileX, flareProjectileY, flareProjectileSize;
  private boolean flareProjectileActive;

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
    flareProjectileActive = false;

    if (isBox) {
      playerW = BOX_W;
      isTeam = false;
    } else {
      playerW = BOX_W;
      isTeam = true;
    }

    ellipseMode(CORNER);
  }

  private void render() { //parameter is 0 if drawing player, 1 if drawing opponent
    //update flare cds and handle flare accordingly
    if (flareCD < FLARE_CD*1000) {
      flareCD = millis() - flareMillis;
      if (flareCD < (FLARE_CD - FLARE_DURATION)*1000) {
        //flare cast animation
        if (flareCD < FLARE_CAST_TIME*1000)
        {
          flareProjectileActive = true;
          flareActive = false;
          if (flareCD < FLARE_CAST_TIME*1000/2) { //draw flare going up
            drawFlareAnimation(true);
          } else { //draw flare going down
            drawFlareAnimation(false);
          }
        } else {
          flareProjectileActive = false;
          flareActive = true;
          drawFlare();
        }
      } else flareActive = false;
    }

    //if (opponentMan.flareActive && !isTeam && isRevealed(opponentMan)) {
    // determineVisibleEnemyCoordinates(opponentMan);
    // drawVisible();
    // //drawBox();
    //}

    //isRevealed(opponentMan) - does opponentMan's flare reveal me?
    if (!isTeam) {
     for (int i = 0; i < 2; i++) {
       if (opponentTeam[i].flareActive && isRevealed(opponentTeam[i])) {
         determineVisibleEnemyCoordinates(opponentTeam[i]);
         drawVisible();
         //drawBox();
       }
     }
    }


    //    println(player + " health " + health);
    //    if (isTeam) drawCircle();
    if (isTeam) drawCircle();

    if (shotFired == 1) drawShot();
    if (soundPulsing) drawSound();
  }

  private void drawFlareAnimation(boolean isFirstHalf) { //is first half of animation or second half?
    pushStyle();
    ellipseMode(CORNER);
    fill(255, 0, 0);
    ellipse(flareProjectileX, flareProjectileY, flareProjectileSize, flareProjectileSize);
    popStyle();

    if (isFirstHalf) {
      flareProjectileSize++;
    } else {
      flareProjectileSize--;
    }

    switch(flareProjectileDirection) {
    case 0: //up
      flareProjectileY-=FLARE_PROJECTILE_SPEED;
      break;
    case 1: //down
      flareProjectileY+=FLARE_PROJECTILE_SPEED;
      break;
    case 2: //left
      flareProjectileX-=FLARE_PROJECTILE_SPEED;
      break;
    case 3: //right
      flareProjectileX+=FLARE_PROJECTILE_SPEED;
      break;
    default:
      break;
    }

    if (flareProjectileX < WINDOW_X) flareProjectileX = WINDOW_X;
    else if (flareProjectileX + flareProjectileSize > WINDOW_X+WINDOW_WIDTH) flareProjectileX = WINDOW_X+WINDOW_WIDTH - flareProjectileSize;
    if (flareProjectileY < WINDOW_Y) flareProjectileY = WINDOW_Y;
    else if (flareProjectileY + flareProjectileSize > WINDOW_Y+WINDOW_WIDTH) flareProjectileY = WINDOW_Y+WINDOW_HEIGHT - flareProjectileSize;
  }

  private void determineVisibleEnemyCoordinates(Player opp) {
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
          visiblePoints[5] = opp.flareY + FLARE_VISION_RANGE;

          visiblePoints[6] = x+playerW;
          visiblePoints[7] = opp.flareY + FLARE_VISION_RANGE;
        }
      } else if (swRevealed) { //(nw, sw) only left two corners are visible. right of flare.
        visiblePoints[0] = x;
        visiblePoints[1] = y;

        visiblePoints[2] = opp.flareX + FLARE_VISION_RANGE;
        visiblePoints[3] = y;

        visiblePoints[4] = x;
        visiblePoints[5] = y+playerW;

        visiblePoints[6] = opp.flareX + FLARE_VISION_RANGE;
        visiblePoints[7] = y + playerW;
      } else //(nw) //only the top left corner is visible. bottom right of flare
      {
        visiblePoints[0] = x;
        visiblePoints[1] = y;

        visiblePoints[2] = opp.flareX + FLARE_VISION_RANGE;
        visiblePoints[3] = y;

        visiblePoints[4] = x;
        visiblePoints[5] = opp.flareY + FLARE_VISION_RANGE;

        visiblePoints[6] = opp.flareX + FLARE_VISION_RANGE;
        visiblePoints[7] = opp.flareY + FLARE_VISION_RANGE;
      }
    } else if (neRevealed) {
      if (seRevealed) { //(ne, se) only right two corners are visible. left of flare
        visiblePoints[0] = opp.flareX;
        visiblePoints[1] = y;

        visiblePoints[2] = x + playerW;
        visiblePoints[3] = y;

        visiblePoints[4] = opp.flareX;
        visiblePoints[5] = y + playerW;

        visiblePoints[6] = x + playerW;
        visiblePoints[7] = y + playerW;
      } else { //(ne) top left corner is visible. bottom left of flare
        visiblePoints[0] = opp.flareX;
        visiblePoints[1] = y;

        visiblePoints[2] = x + playerW;
        visiblePoints[3] = y;

        visiblePoints[4] = opp.flareX;
        visiblePoints[5] = opp.flareY + FLARE_VISION_RANGE;

        visiblePoints[6] = x + playerW;
        visiblePoints[7] = opp.flareY + FLARE_VISION_RANGE;
      }
    } else if (swRevealed) {
      if (seRevealed) { //(sw, se) bottom two corners are visible. top of flare
        visiblePoints[0] = x;
        visiblePoints[1] = opp.flareY;

        visiblePoints[2] = x + playerW;
        visiblePoints[3] = opp.flareY;

        visiblePoints[4] = x;
        visiblePoints[5] = y + playerW;

        visiblePoints[6] = x + playerW;
        visiblePoints[7] = y + playerW;
      } else { //(sw) //bottom left corner is visible. top right of flare
        visiblePoints[0] = x;
        visiblePoints[1] = opp.flareY;

        visiblePoints[2] = opp.flareX + FLARE_VISION_RANGE;
        visiblePoints[3] = opp.flareY;

        visiblePoints[4] = x;
        visiblePoints[5] = y + playerW;

        visiblePoints[6] = opp.flareX + FLARE_VISION_RANGE;
        visiblePoints[7] = y + playerW;
      }
    } else { //(se) bottom right corner is visible. top left of flare
      visiblePoints[0] = opp.flareX;
      visiblePoints[1] = opp.flareY;

      visiblePoints[2] = x + playerW;
      visiblePoints[3] = opp.flareY;

      visiblePoints[4] = opp.flareX;
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
    noStroke();
    fill(235, 116, 19);
    rect(flareX, flareY, FLARE_VISION_RANGE, FLARE_VISION_RANGE);
    popStyle();
  }

  private void drawSound() {
    pushStyle();
    ellipseMode(CENTER);
    stroke(255, 255, 0);
    noFill();
    ellipse(pulseCenterX, pulseCenterY, pulseEllipseD, pulseEllipseD);
    pulseEllipseD += 25;
    ellipseMode(CORNER);
    popStyle();
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

  private void checkShotCollisionForPlayers(Player opp) { //will probably stay same for client in 1v2
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
    if (projectileStartX <= WINDOW_X || projectileStartX >= WINDOW_WIDTH + WINDOW_X) {
      shotFired = 0;
      soundPulsing = false;
    }
    if (projectileStartY <= WINDOW_Y || projectileStartY >= WINDOW_HEIGHT + WINDOW_Y) {
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
    if (isTeam) checkShotCollisionForPlayers(opponentMan);
    else {
      checkShotCollisionForPlayers(opponentTeam[0]);
      checkShotCollisionForPlayers(opponentTeam[1]);
    }
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

  private void drawVisible() {
    pushStyle();
    noStroke();
    fill(255, 0, 0);
    quad(visiblePoints[0], visiblePoints[1], visiblePoints[2], visiblePoints[3], visiblePoints[6], visiblePoints[7], visiblePoints[4], visiblePoints[5]);
    drawDirectionalIndicator();
    popStyle();
  }

  private void drawCircle() {
    rect(x, y, BOX_W, BOX_W);
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
      x = data[1];
      y = data[2];
      direction = data[3];
      projectileStartX = data[4];
      projectileStartY = data[5];
      projectileEndX = data[6];
      projectileEndY = data[7];
      shotFired = data[8];
      projectileDirection = data[9];
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

      if (isLegal && y != WINDOW_Y) y-=5;

      direction = 0;
    } else if (movementDirection == 1) {
      if (y+playerW == opponentMan.y) {
        if ((x >= opponentMan.x && x < opponentMan.x+opponentMan.playerW) ||
          (x+playerW>opponentMan.x && x+playerW<=opponentMan.x+opponentMan.playerW) ||
          (x<opponentMan.x && x < opponentMan.x+opponentMan.playerW && x+playerW>opponentMan.x && x+playerW>opponentMan.x+opponentMan.playerW)) {
          isLegal = false;
        }
      }
      if (isLegal && y != (WINDOW_HEIGHT + WINDOW_Y - playerW)) y+=5;
      direction = 1;
    } else if (movementDirection == 2) {
      if (x == opponentMan.x+opponentMan.playerW) {
        if ((y >= opponentMan.y && y < opponentMan.y+opponentMan.playerW) ||
          (y+playerW>opponentMan.y && y+playerW <= opponentMan.y+opponentMan.playerW) ||
          (y<opponentMan.y && y < opponentMan.y+opponentMan.playerW && y+playerW>opponentMan.y && y+playerW>opponentMan.y+opponentMan.playerW)) {
          isLegal = false;
        }
      }

      if (isLegal && x != WINDOW_X) x-=5;
      direction = 2;
    } else if (movementDirection == 3) {
      if (x+playerW == opponentMan.x) {
        if ((y >= opponentMan.y && y < opponentMan.y+opponentMan.playerW) ||
          (y+playerW>opponentMan.y && y+playerW <= opponentMan.y+opponentMan.playerW) ||
          (y<opponentMan.y && y < opponentMan.y+opponentMan.playerW && y+playerW>opponentMan.y && y+playerW>opponentMan.y+opponentMan.playerW)) {
          isLegal = false;
        }
      }

      if (isLegal && x != WINDOW_WIDTH + WINDOW_X - playerW) x+=5;
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
    if (!flareProjectileActive) {
      flareProjectileSize = FLARE_PROJECTILE_BASE_SIZE;
      flareProjectileX = x + playerW;
      flareProjectileY = y + playerW;
      flareProjectileDirection = direction;

      //      if (flareProjectileX < WINDOW_X) flareProjectileX = 0;
      //      if (flareProjectileX > WINDOW_X + WINDOW_WIDTH) flareProjectileX = WINDOW_WIDTH + WINDOW_X - FLARE_PROJECTILE_RANGE;

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

        if (flareX < WINDOW_X) flareX = WINDOW_X;
        else if (flareX + FLARE_VISION_RANGE > WINDOW_X + WINDOW_WIDTH) flareX = WINDOW_X + WINDOW_WIDTH - FLARE_VISION_RANGE;
        if (flareY < WINDOW_Y) flareY = WINDOW_Y;
        else if (flareY + FLARE_VISION_RANGE > WINDOW_Y + WINDOW_WIDTH) flareY = WINDOW_Y + WINDOW_WIDTH - FLARE_VISION_RANGE;

        flareCD = 0;
        flareMillis = millis();
      }
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
    if (isTeam) {
      x = PLAYER1_START_X + WINDOW_X;
      y = PLAYER1_START_Y + WINDOW_Y;
      direction = PLAYER1_START_DIRECTION;
    } else
    {
      x = PLAYER2_START_X + WINDOW_X;
      y = PLAYER2_START_Y + WINDOW_Y;
      direction = PLAYER2_START_DIRECTION;
    }
  }

  public String getData() {
    return ("2 " + x + " " + y + " " + direction + " " + projectileStartX + " " + projectileStartY + " " + projectileEndX + " " + projectileEndY + " " + shotFired + " " + projectileDirection + "\n");
  }
}
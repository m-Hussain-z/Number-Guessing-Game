#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN_MENU()
{
  echo Enter your username:
  read NAME
  FORMATTED_USER_NAME=$(echo "$NAME" | sed 's/^ *//;s/ *$//')
  USER=$($PSQL "SELECT * FROM users WHERE username = '$FORMATTED_USER_NAME'")
  SECRET_NUMBER=$((RANDOM % 1000 + 1))
  GUESS=0
  if [[ -z $USER ]]
  then
    echo Welcome, $FORMATTED_USER_NAME! It looks like this is your first time here.
    INSERT_USER=$($PSQL "INSERT INTO users(username,games_played,best_game) VALUES('$FORMATTED_USER_NAME',1,0)")
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$FORMATTED_USER_NAME'")
    NEW_USER=$($PSQL "SELECT * FROM users WHERE username = '$FORMATTED_USER_NAME'")
    GAME "Guess the secret number between 1 and 1000:" "$USER_ID" "$GUESS"
  else
    
    echo "$USER" | while IFS='|' read USER_ID USER_NAME GAME_PLAYED BEST_GUESS
    do
      PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID")
      BEST_GUESS=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id = $USER_ID")
      UPDATE_OLD_USER=$($PSQL "UPDATE users SET best_game = $BEST_GUESS WHERE username= '$USER_NAME'")
      echo Welcome back, $USER_NAME! You have played $PLAYED games, and your best game took $BEST_GUESS guesses.
      UPDATE_OLD_USER=$($PSQL "UPDATE users SET games_played = $PLAYED + 1 WHERE username= '$USER_NAME'")
    done
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$FORMATTED_USER_NAME'")
    GAME "Guess the secret number between 1 and 1000:" "$USER_ID" "$GUESS"
    
  fi
}

GAME()
{ 
  if [[ $1 ]]
  then
   echo -e "\n$1"
  fi
  read NUMBER
  
  USER_ID=$2
  GUESS=$3
   
  if [[ ! $NUMBER =~ ^[0-9]+$ ]]
  then
    GAME "That is not an integer, guess again:" "$USER_ID" "$GUESS"
  else
    if [[ $NUMBER -gt $SECRET_NUMBER ]]
    then
      GUESS=$((GUESS +1))
      GAME "It's lower than that, guess again:" "$USER_ID" "$GUESS"
    elif [[ $NUMBER -lt $SECRET_NUMBER ]]
    then
      GUESS=$((GUESS +1))
      GAME "It's higher than that, guess again:" "$USER_ID" "$GUESS"
    else
      GUESS=$((GUESS +1))
      echo You guessed it in $GUESS tries. The secret number was $SECRET_NUMBER. Nice job!
      NEW_GAME=$($PSQL "INSERT INTO games(number_of_guesses,user_id) VALUES($GUESS,$USER_ID)")
    fi
  fi

}

MAIN_MENU

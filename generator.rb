#Name: Password Manager
#Date: 3/6/23
#Creator: Lorenzo Juarez

#Description:
#This is a password manager program that allows the user to generate and store passwords for different websites.
# The passwords are stored in an SQLite database and can be retrieved, modified, or deleted as needed.
require 'sqlite3'
require 'securerandom'
require 'io/console'
require 'win32/clipboard'
require 'uri'
require 'colorize'

RED = "\e[31m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
BLUE = "\e[34m"
Purple = "\e[35m"
T = "\e[36m"
STOP_COLOR = "\e[0m"

# Open a connection to the database
db = SQLite3::Database.new "passwords.db"

# Create the passwords table if it doesn't exist
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS passwords (
    id INTEGER PRIMARY KEY,
    password TEXT,
    label TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
SQL

# Generate a random password
def generate_password(length)
  chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*()_+-=[]{}|;:",./<>?'
  password = ''
  length.times { password << chars[rand(chars.size)] }
  password.gsub!(/\d/) { rand(10).to_s }
  password.gsub!(/[A-Z]/) { ('A'..'Z').to_a[rand(26)] }
  password.gsub!(/[^A-Za-z0-9]/) { chars[rand(chars.size)] }
  password
end

# Print the instructions
puts "Password Manager".colorize(:blue)
puts "To generate a new password, enter the label for the website. ex#{YELLOW} Twitter, Youtube#{STOP_COLOR}"
puts "To retrieve a password, enter the label for the website again."
puts "Type '#{ 'all'.colorize(:green) }' to view all labels, or '#{ 'q'.colorize(:red) }' to quit."
puts"\n"

loop do
  # Prompt the user for a label or command
  print "#{Purple}Enter the label for the website, #{GREEN}'all' to view all labels, or #{RED}'q' to quit: #{STOP_COLOR}"
  input = gets.chomp.downcase
  if input =~ /\A#{URI::regexp(['http', 'https'])}\z/
    label = URI.parse(input).host
  else
    label = input
  end

  break if input == 'q'

  if input == 'all'
    # Retrieve all labels from the database
    rows = db.execute("SELECT label FROM passwords")

    if rows.empty?
      puts "No labels found."
    else
      # Print the labels
      puts "Labels:"
      rows.each do |row|
        puts row[0]
      end
    end
  else
    # Check if the label exists in the database
    rows = db.execute("SELECT EXISTS(SELECT 1 FROM passwords WHERE label = ?)", input)

    if rows.flatten.first == 1
      # Retrieve the existing password from the database
      rows = db.execute("SELECT password FROM passwords WHERE label = ?", input)
      password = rows.first.first

      # Prompt the user to retrieve, modify, or delete the password
      print "Enter 'r' to retrieve the password, 'm' to modify the password, or 'd' to delete the password: "
      choice = gets.chomp.downcase

      case choice
      when 'r'
        # Show the password
        puts "Password: #{password}"

        # Copy the password to the clipboard
        Win32::Clipboard.set_data(password)
        puts "Password copied to clipboard."
      when 'm'
        # Show the existing password
        puts "Existing Password: #{password}"

        # Prompt the user for a new password
        print "Enter a new password, or press enter to generate a new random password: "
        new_password = gets.chomp

        if new_password.empty?
          # Generate a new random password
          new_password = generate_password(16)
        end

        # Update the password in the database
        if label
          db.execute("UPDATE passwords SET password = ? WHERE label = ?", new_password, label)
          puts "Password updated successfully."
        else
          puts "Label not found."
        end
      when 'd'
        # Delete the password from the database
        db.execute("DELETE FROM passwords WHERE label = ?", label)

        puts "Password deleted successfully."
      else
        puts "Invalid choice."
      end
    else
      # Generate a random password
      password = generate_password(16)

      # Store the password and label in the database
      db.execute("INSERT INTO passwords (password, label) VALUES (?, ?)", password, label)

      # Print the password and label
      puts "Password: #{password}"
      puts "Label: #{label}"

      # Copy the password to the clipboard
      Win32::Clipboard.set_data(password)
      puts "Password copied to clipboard."
    end
  end
  end
  # Close the database connection
  db.close

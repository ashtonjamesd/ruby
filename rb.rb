module TokenType
  INTEGER = 0
  BAD = 1

  SINGLE_EQUALS = 2
  IDENTIFIER = 3
end

class Token
  attr_reader :type, :value

  def initialize(type, value)
    @type = type
    @value = value
  end
end

class Lexer
  attr_reader :tokens

  def initialize(input)
    @input = input
    @position = 0
    @tokens = []
  end

  def advance()
    @position += 1
  end

  def tokenizeInteger
    start = @position

    while @position < @input.length
      char = @input[@position]

      if char >= '0' && char <= '9'
        advance()
      else
        break
      end
    end

    value = @input[start...@position]
    token = Token.new(TokenType::INTEGER, value)
    return token
  end

  def tokenizeIdentifier()
    start = @position

    while @position < @input.length
      char = @input[@position]

      if (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || 
        (char >= '0' && char <= '9') || char == '_'
        advance()
      else
        break
      end
    end

    value = @input[start...@position]
    token = Token.new(TokenType::IDENTIFIER, value)
    return token
  end

  def tokenizeSymbol()
    char = @input[@position]
    advance()

    if char == '='
      return Token.new(TokenType::SINGLE_EQUALS, char)
    end
  end

  def tokenize()
    if (@input[@position] == ' ')
      advance()
      return nil
    end

    if (@input[@position] == "\n")
      advance()
      return nil
    end

    if (@input[@position] >= '0' && @input[@position] <= '9')
      return tokenizeInteger()
    end

    if (@input[@position] >= 'a' && @input[@position] <= 'z')
      return tokenizeIdentifier()
    end

    return tokenizeSymbol()
  end

  def run()
    while @position < @input.length
      token = tokenize()
      if token.nil? then next end

      @tokens.push(token)
    end
  end
end

class Statement end

class IntegerLiteral < Statement
  attr_reader :value

  def initialize(value)
    @value = value
  end
end

class IdentifierLiteral < Statement
  attr_reader :value

  def initialize(value)
    @value = value
  end
end

class AssignmentStatement < Statement
  attr_reader :identifier, :expression

  def initialize(identifier, expression)
    @identifier = identifier
    @expression = expression
  end
end

class Parser
  attr_reader :statements

  def initialize(tokens)
    @tokens = tokens
    @position = 0
    @statements = []
  end

  def parseAssignment()
    @token = @tokens[@position]
    @position += 1

    @position += 1

    expression = parsePrimary()
    statement = AssignmentStatement.new(@token.value, expression)

    return statement
  end

  def parsePrimary()
    token = @tokens[@position]

    case token.type
    when TokenType::INTEGER
      @position += 1
      return IntegerLiteral.new(token.value)
    when TokenType::IDENTIFIER
      @position += 1
      return IdentifierLiteral.new(token.value)
    else
      puts "Unexpected token: #{token.type}"
    end
  end

  def parseStatement()
    @token = @tokens[@position]

    case @token.type
    when TokenType::IDENTIFIER
      parseAssignment()
    else
      puts "Unexpected token: #{@token.type}"
    end
  end

  def parse()
    while @position < @tokens.length
      statement = parseStatement()
      @statements.push(statement)
    end
  end
end

source = File.open("example.rb", "r")

lexer = Lexer.new(source.read)
lexer.run()

# lexer.tokens.each do |token|
#   puts "Token: #{token.type}: #{token.value}"
# end
#

parser = Parser.new(lexer.tokens)
parser.parse()

# for statement in parser.statements
#   case statement
#   when AssignmentStatement
#     puts "Assignment:"
#     puts "  Identifier: #{statement.identifier}"
#     puts "  Value: #{statement.expression.value}"
#   else
#     puts "Unknown statement"
#   end
# end
# 
#
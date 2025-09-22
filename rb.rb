module InterpreterResult
  RUNTIME_ERROR = 0
  COMPILER_ERROR = 1
  OK = 2
end

module TokenType
  INTEGER = 0
  BAD = 1

  SINGLE_EQUALS = 2
  IDENTIFIER = 3

  PLUS = 4
  MINUS = 5
  STAR = 6
  SLASH = 7
  MOD = 8
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

    case char
    when '+'
      return Token.new(TokenType::PLUS, char)
    when '-'
      return Token.new(TokenType::MINUS, char)
    when '*'
      return Token.new(TokenType::STAR, char)
    when '/'
      return Token.new(TokenType::SLASH, char)
    when '%'
      return Token.new(TokenType::MOD, char)
    when '='
      return Token.new(TokenType::SINGLE_EQUALS, char)
    else
      puts "Bad token symbol in the lexer"
      return Token.new(TokenType::BAD, char)
    end
  end

  def tokenize()
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
      while @position < @input.length && (@input[@position] == ' '|| @input[@position] == "\n" || @input[@position] == "\t")
        advance()
      end

      token = tokenize()
      if token.nil? then break end

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

class BinaryExpression < Statement
  attr_reader :left, :right, :operator

  def initialize(left, right, operator)
    @left = left
    @right = right
    @operator = operator
  end
end

class MethodCall < Statement
  attr_reader :name, :arguments

  def initialize(name, arguments)
    @name = name
    @arguments = arguments
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

  def advance()
    @position += 1
  end

  def recede()
    @position -= 1
  end

  def current()
    return @tokens[@position]
  end

  def isEnd()
    return current() == nil
  end

  def match(type)
    return current().type == type unless isEnd()
    return false
  end

  def parseAssignment()
    @token = current()
    advance()

    advance()

    expression = parsePrimary()
    statement = AssignmentStatement.new(@token.value, expression)

    return statement
  end

  def parsePrimary()
    token = current()

    case token.type
    when TokenType::INTEGER
      advance()
      return IntegerLiteral.new(token.value)
    when TokenType::IDENTIFIER
      advance()
      return IdentifierLiteral.new(token.value)
    else
      advance()
      puts "Unexpected primary token: #{token.type}"
    end
  end

  def parseMethodCall()
    name = current()
    advance()

    arguments = []
    arg = parseExpression()
    arguments.push(arg)

    return MethodCall.new(name.value, arguments)
  end

  def parseIdentifier()
    advance()

    token = current()

    if isEnd()
      return nil
    end

    case token.type
    when TokenType::SINGLE_EQUALS
      recede()
      return parseAssignment()
    when TokenType::IDENTIFIER
      recede()
      return parseMethodCall()
    when TokenType::INTEGER
      recede()
      return parseMethodCall()
    end
  end

  def parseTerm()
    left = parsePrimary()

    while match(TokenType::PLUS) || match(TokenType::MINUS)
      operator = current()
      advance()

      right = parsePrimary()
      left = BinaryExpression.new(left, right, operator)
    end

    return left
  end

  def parseFactor()
    left = parseTerm()

    while match(TokenType::STAR) || match(TokenType::SLASH) || match(TokenType::MOD)
      operator = current()
      advance()

      right = parseTerm()
      left = BinaryExpression.new(left, right, operator)
    end

    return left
  end

  def parseExpression()
    return parseFactor()
  end

  def parseStatement()
    @token = current()

    case @token.type
    when TokenType::IDENTIFIER
      return parseIdentifier()
    else
      return parseExpression()
    end
  end

  def parse()
    while @position < @tokens.length
      statement = parseStatement()
      @statements.push(statement)
    end
  end

  def printAstStatement(statement, depth)
    print "  " * depth

    case statement
    when IntegerLiteral
      puts "Integer literal: #{statement.value}"
    when IdentifierLiteral
      puts "Identifier literal: #{statement.value}"
    when AssignmentStatement
      puts "Assignment:"
      puts "  Identifier: #{statement.identifier}"
      printAstStatement(statement.expression, depth + 1)
    when MethodCall
      puts "Method call:"
      puts "  Name: #{statement.name}"
      
      for arg in statement.arguments
        printAstStatement(arg, depth + 1)
      end
    when BinaryExpression
      puts "Binary expression:"
      puts "  Operator: #{statement.operator.value}"
      printAstStatement(statement.left, depth + 1)
      printAstStatement(statement.right, depth + 1) if statement.right
    when nil
      puts "Nil AST statement"
    else
      puts "Unknown statement"
    end
  end

  def printAst()
    for statement in @statements
      printAstStatement(statement, 0)
    end
  end
end

module Bytecode
  METHOD_CALL = 0
  LITERAL = 1
  SET_LOCAL = 2

  OP_PLUS = 3
  OP_MINUS = 4
  OP_STAR = 5
  OP_SLASH = 6
  OP_MOD = 7
end

class Program
  attr_reader :bytecode

  def initialize(bytecode)
    @bytecode = bytecode
  end
end

class BytecodeCompiler
  attr_reader :bytecode

  def initialize(ast)
    @ast = ast
    @bytecode = []
  end

  def compileStatement(statement)
    case statement
      when IntegerLiteral
        @bytecode.push(Bytecode::LITERAL)
        @bytecode.push(statement.value)
      when IdentifierLiteral
        @bytecode.push(Bytecode::LITERAL)
        @bytecode.push(statement.value)
      when MethodCall
        for arg in statement.arguments
          compileStatement(arg)
        end

        @bytecode.push(Bytecode::LITERAL)

        @bytecode.push(statement.name)
        @bytecode.push(Bytecode::METHOD_CALL)
      when AssignmentStatement
        compileStatement(statement.expression)

        @bytecode.push(Bytecode::LITERAL)
        @bytecode.push(statement.identifier)

        @bytecode.push(Bytecode::SET_LOCAL)
      when BinaryExpression
        compileStatement(statement.left)
        compileStatement(statement.right)

        case statement.operator.type
        when TokenType::PLUS
          @bytecode.push(Bytecode::OP_PLUS)
        when TokenType::MINUS
          @bytecode.push(Bytecode::OP_MINUS)
        when TokenType::STAR
          @bytecode.push(Bytecode::OP_STAR)
        when TokenType::SLASH
          @bytecode.push(Bytecode::OP_SLASH)
        when TokenType::MOD
          @bytecode.push(Bytecode::OP_MOD)
        else
          puts "Unknown binary operator #{statement.operator.type}"
          return InterpreterResult::COMPILER_ERROR
        end
      else
        puts "Unknown statement type in compiler"
        return InterpreterResult::COMPILER_ERROR
    end
  end

  def compileAst()
    for statement in @ast
      compileStatement(statement)
    end
  end
end

class BytecodeInterpreter
  def initialize(bytecode)
    @bytecode = bytecode
    @pc = 0
    @stack = []
    @locals = {}
  end

  def tick()
    @pc += 1
  end

  def pushLiteral()
    value = @bytecode[@pc + 1]
    @stack.push(value)

    tick()
    tick()
  end

  def callMethod()
    tick()

    methodName = @stack.pop()
    argument = pullStackValue()

    if @locals.key?(argument)
      argument = @locals[argument]
    end

    case methodName
    when "puts"
      puts argument
    else
      puts "Unknown method '#{methodName}'"
      return InterpreterResult::RUNTIME_ERROR
    end
  end

  def setLocal()
    tick()

    identifier = @stack.pop()
    value = @stack.pop()

    @locals[identifier] = value
  end

  def pullStackValue()
    value = @stack.pop()
    
    if @locals.key?(value)
      value = @locals[value]
    end

    return value
  end

  def plus()
    right = pullStackValue()
    left = pullStackValue()

    result = left.to_i + right.to_i 
    @stack.push(result)

    tick()
  end

  def minus()
    right = pullStackValue()
    left = pullStackValue()

    result = left.to_i - right.to_i
    @stack.push(result)

    tick()
  end

  def multiply()
    right = pullStackValue()
    left = pullStackValue()

    result = left.to_i * right.to_i
    @stack.push(result)

    tick()
  end

  def divide()
    right = pullStackValue()
    left = pullStackValue()

    if right.to_i == 0
      puts "Runtime error: Division by zero"
      return InterpreterResult::RUNTIME_ERROR
    end

    result = left.to_i / right.to_i
    @stack.push(result)

    tick()
  end

  def mod()
    right = pullStackValue()
    left = pullStackValue()

    if right.to_i == 0
      puts "Runtime error: Modulo by zero"
      return InterpreterResult::RUNTIME_ERROR
    end

    result = left.to_i % right.to_i
    @stack.push(result)

    tick()
  end

  def execute(bytecode)
    case bytecode
    when Bytecode::LITERAL
      pushLiteral()
    when Bytecode::METHOD_CALL
      callMethod() 
    when Bytecode::SET_LOCAL
      setLocal()
    when Bytecode::OP_PLUS
      plus()
    when Bytecode::OP_MINUS
      minus()
    when Bytecode::OP_STAR
      multiply()
    when Bytecode::OP_SLASH
      divide()
    when Bytecode::OP_MOD
      mod()
    else
      puts "Unknown bytecode: #{bytecode}"
      tick()
      return InterpreterResult::RUNTIME_ERROR
    end

    return InterpreterResult::OK
  end

  def interpret()
    while @pc < @bytecode.length
      result = execute(@bytecode[@pc])

      if result != InterpreterResult::OK
        return result
      end
    end

    return InterpreterResult::OK
  end
end

def rubyInterpreter()
  cmd_arg = ARGV[0]
  source = File.open(cmd_arg, "r")

  dump_lexer = false
  dump_parser = false
  dump_compiler = false
  dump_interpreter = false

  for arg in ARGV
    if arg == "--dump=lexer"
      dump_lexer = true
    elsif arg == "--dump=parser"
      dump_parser = true
    elsif arg == "--dump=compiler"
      dump_compiler = true
    elsif arg == "--dump=interpreter"
      dump_interpreter = true
    elsif arg == "--help"
      puts "Usage: ruby rb.rb <source_file> [--dump=lexer|parser|compiler|interpreter]"
      return InterpreterResult::OK
    end

  end

  lexer = Lexer.new(source.read)
  lexer.run()

  if dump_lexer
    puts "\nLexer Tokens:"
    for token in lexer.tokens
      puts "Token: #{token.type}: #{token.value}"
    end
  end

  parser = Parser.new(lexer.tokens)
  parser.parse()

  if dump_parser
    puts "\nParser AST:"
    parser.printAst()
  end

  compiler = BytecodeCompiler.new(parser.statements)
  compiler.compileAst()

  if dump_compiler
    puts "\nBytecode Program:"
    for b in compiler.bytecode
      case b
      when Bytecode::LITERAL
        puts "Bytecode: LITERAL"
      when Bytecode::METHOD_CALL
        puts "Bytecode: METHOD_CALL"
      when Bytecode::SET_LOCAL
        puts "Bytecode: SET_LOCAL"
      when Bytecode::OP_PLUS
        puts "Bytecode: OP_PLUS"
      when Bytecode::OP_MINUS
        puts "Bytecode: OP_MINUS"
      when Bytecode::OP_STAR
        puts "Bytecode: OP_STAR"
      when Bytecode::OP_SLASH
        puts "Bytecode: OP_SLASH"
      when Bytecode::OP_MOD
        puts "Bytecode: OP_MOD"
      else
        puts "Bytecode: #{b}"
      end
    end
  end

  interpreter = BytecodeInterpreter.new(compiler.bytecode)
  result = interpreter.interpret()

  return result 
end

interpretResult = rubyInterpreter()

puts "\nRuby interpreter finished execution."

case interpretResult
when InterpreterResult::OK
  puts "Execution finished successfully."
when InterpreterResult::COMPILER_ERROR
  puts "Execution failed due to a compiler error."
when InterpreterResult::RUNTIME_ERROR
  puts "Execution failed due to a runtime error."
else
  puts "Execution failed due to an unknown error."
end
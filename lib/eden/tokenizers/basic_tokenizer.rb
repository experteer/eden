require 'rubygems'
require 'ruby-debug'

module Eden
  module BasicTokenizer
    def tokenize_single_character
      @thunk_end += 1
      token = Token.new(@state, thunk)
      @i += 1
      reset_thunk!
      default_state_transitions!
      return token
    end

    def tokenize_rcurly
      @thunk_end += 1
      old_state = @interpolating.delete_at(-1)
      tokens = []
      if old_state
        tokens << Token.new(@state, thunk)
        @i += 1
        reset_thunk!
        @state = old_state
        tokens << tokenize_double_quote_string
      else
        tokens << Token.new(@state, thunk)
        @i += 1
        reset_thunk!
      end
      default_state_transitions!
      return tokens
    end

    def tokenize_identifier
      advance until( /[A-Za-z0-9_]/.match( cchar ).nil? )
      translate_keyword_tokens(capture_token( @state ))
    end

    def tokenize_whitespace
      advance until( cchar != ' ' && cchar != '\t' )
      capture_token( :whitespace )
    end

    def tokenize_instancevar
      advance # Pass the @ symbol
      advance until( /[a-z0-9_]/.match( cchar ).nil? )
      capture_token( :instancevar )
    end

    def tokenize_classvar
      advance(2) # Pass the @@ symbol
      advance until( /[a-z0-9_]/.match( cchar ).nil? )
      capture_token( :classvar )
    end

    def tokenize_symbol
      advance # Pass the :
      case cchar
      when '"'  then return tokenize_double_quote_string
      when '\'' then return tokenize_single_quote_string
      end
      advance until( cchar == ' ' || cchar.nil? )
      capture_token( :symbol )
    end

    # Takes an identifier token, and tranforms its type to
    # match Ruby keywords where the identifier is actually a keyword.
    # Reserved words are defined in S.8.5.1 of the Ruby spec.
    def translate_keyword_tokens( token )
      keywords = ["__LINE__", "__ENCODING__", "__FILE__", "BEGIN",   
                  "END", "alias", "and", "begin", "break", "case",
                  "class", "def", "defined?", "do", "else", "elsif",
                  "end", "ensure", "false", "for", "if", "in",
                  "module", "next", "nil", "not", "or", "redo",
                  "rescue", "retry", "return", "self", "super",
                  "then", "true", "undef", "unless", "until", 
                  "when", "while", "yield"]
      if keywords.include?( token.content )
        token.type = token.content.downcase.to_sym
      end
      
      # A couple of exceptions
      token.type = :begin_global if token.content == "BEGIN"
      token.type = :end_global if token.content == "END"

      return token
    end
  end
end

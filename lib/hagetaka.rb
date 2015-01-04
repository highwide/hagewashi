require'pry'
module Hagetaka
  class Controller
    def initialize
      @players = []
      @token_cards = TokenCard.all.shuffle
      @carryover_cards = []

      # 人間プレイヤーが1人
      @players << Player.new(name: "あなた")
      3.times { |i| @players << ComputerPlayer.new(name: "コンピュータ#{i + 1}")}

      # プレイヤーにカードを配る
      @players.each { |player| player.set_hand_cards }
    end

    def start
      while @players.first.hand_cards.size > 0
        @token_card = @token_cards.first
        puts_game_info
        played_cards = []

        # プレイヤーは場に出すカードを決める
        @players.each do |player|
          number = player.select_playing_card
          played_cards << player.play_card(number)
        end
        
        puts_played_cards(played_cards)

        sleep 1

        puts_result

        sleep 1
      end
      puts_game_winner
    end

    private

    def puts_game_info
      puts "\n==== Turn Start==="

      puts "# #{@players.first.name}が持っているカード"
      puts @players.first.hand_cards_info

      puts '# 場に出されたカード'
      puts @token_card.number
      
      if @carryover_cards.size > 0
        puts '# キャリーオーバーされているカード'
        puts @carryover_cards.number.join(' ')
      end
    end
   
    def puts_played_cards(played_cards)
      puts "\n=== みんなが出したカード ==="

      played_cards.each do |played_card|
        puts "#{played_card.owner.name}: #{played_card.number}"
      end

      sleep 1

      winner = judge_winner(played_cards)
      if winner == 0
        puts "\n#{@token_card.number}はキャリーオーバーになりました"
        @carryover_cards << @token_card
      else 
        puts "\n#{winner.name}が#{@token_card.number}を取りました"
        winner.point_cards << @token_card
      end
      @token_cards = @token_cards.drop(1)

      if @carryover_cards.size > 0 && winner != 0
        puts "\n#{winner.name}が#{@carryover_cards.map{number.join(' ')}}も取りました"
        @carryover_cards.each { |card| card.owner = winner }
        @carryover_cards = []
      end
    end

    def judge_winner(played_cards)
      #場札が1以上なら大きい数字を出した人が勝ち
      if @token_card.number > 0
        played_cards.sort! { |a, b| b <=> a }
      else
        played_cards.sort! 
      end

      # 重複した数字を出した場合は、その次の人が勝ち
      while played_cards[0].number == played_cards[1].number
        duplication_number = played_cards[0].number
        played_cards = played_cards.delete_if { |card| card.number == duplication_number }
        return 0 if played_cards.empty?
      end
      played_cards[0].owner
    end

    def puts_result
      puts "\n=== Result ==="

      @players.each do |player|
        puts "# #{player.name}のスコア"
        puts "得点: #{player.point_cards_info}"
      end
    end

    def puts_game_winner
      puts "\n=== Winner ==="
      game_winner = @players.max_by { |player| player.point_cards_info }
      puts "#{game_winner.name}さんが勝ちました"
    end
  end

  class Player
    attr_reader   :hand_cards, :name
    attr_accessor :point_cards

    def initialize(name: '名無し')
      @hand_cards  = []
      @point_cards = []
      @name        = name
    end

    def set_hand_cards
      @hand_cards = (1..15).map { |number| HandsCard.new(number, self) }
    end

    def hand_cards_info
      @hand_cards.map(&:number).join(' ')
    end
    
    def select_playing_card
      puts "\n----"
      puts '出すカードの数字を入力してね！'
      print '> '
      number = gets.chomp.to_i
      unless has_card?(number)
        puts "「#{number}」というカードは持っていないよ！"
        number = select_playing_card
      end
      number
    end

    def has_card?(number)
      @hand_cards.any? { |card| card.number == number }
    end

    def play_card(number)
      card = @hand_cards.find { |card| card.number == number }
      @hand_cards.delete(card)
      card
    end

    def point_cards_info
      point = @point_cards.inject(0) { |p, n| p + n.number }
    end
  end

  class ComputerPlayer < Player
    # ランダムでカードを出す
    def select_playing_card
      @hand_cards.shuffle.first.number
    end
  end

  class HandsCard
    attr_reader   :number
    attr_accessor :owner

    include Comparable
    
    def initialize(number, owner)
      @number = number
      @owner  = owner
    end

    def <=>(other)
      number <=> other.number
    end
  end

  class TokenCard
    attr_reader   :number
    attr_accessor :owner

    def initialize(number)
      @number = number
      @owner  = nil
    end

    def self.all
      ((-5..-1).to_a + (1..10).to_a).map { |number| TokenCard.new(number) }
    end
  end
end

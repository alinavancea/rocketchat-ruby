module RocketChat
  module Messages
    #
    # Rocket.Chat Room messages template (groups&channels)
    #
    class Room
      def self.inherited(subclass)
        field = subclass.name.split('::')[-1].downcase
        collection = field + 's'
        subclass.send(:define_singleton_method, :field) { field }
        subclass.send(:define_singleton_method, :collection) { collection }
      end

      #
      # @param [Session] session Session
      #
      def initialize(session)
        @session = session
      end

      # Full API path to call
      def self.api_path(method)
        "/api/v1/#{collection}.#{method}"
      end

      #
      # *.create REST API
      # @param [String] name Room name
      # @param [Hash] options Additional options
      # @return [Room]
      # @raise [HTTPError, StatusError]
      #
      def create(name, options = {})
        response = session.request_json(
          self.class.api_path('create'),
          method: :post,
          body: {
            name: name
          }.merge(room_option_hash(options))
        )
        RocketChat::Room.new response[self.class.field]
      end

      #
      # *.info REST API
      # @param [String] room_id Rocket.Chat room id
      # @param [String] name Room name (channels since 0.56)
      # @return [Room]
      # @raise [HTTPError, StatusError]
      #
      def info(room_id: nil, name: nil)
        response = session.request_json(
          self.class.api_path('info'),
          body: room_params(room_id, name),
          upstreamed_errors: ['error-room-not-found']
        )

        RocketChat::Room.new response[self.class.field] if response['success']
      end

      #
      # *.rename REST API
      # @param [String] room_id Rocket.Chat room id
      # @param [String] new_name New room name
      # @return [Boolean]
      # @raise [HTTPError, StatusError]
      #
      def rename(room_id, new_name)
        session.request_json(
          self.class.api_path('rename'),
          method: :post,
          body: { roomId: room_id, name: new_name }
        )['success']
      end

      private

      attr_reader :session

      def room_params(id, name)
        if id
          { roomId: id }
        elsif name
          { roomName: name }
        end
      end

      def room_option_hash(options)
        args = [options, :members, :read_only, :custom_fields]

        options = Util.slice_hash(*args)
        return {} if options.empty?

        new_hash = {}
        options.each { |key, value| new_hash[Util.camelize(key)] = value }
        new_hash
      end
    end
  end
end
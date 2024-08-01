module Exporter
  class ExportSurahRecitation < BaseExporter
    attr_accessor :recitation

    def initialize(recitation:, base_path:)
      super(base_path: base_path, name: "surah_recitation_#{recitation.name.to_s.downcase.gsub(/\s+/, '-')}")
      @recitation = recitation
    end

    def export_json
      FileUtils.mkdir_p(@export_file_path)
      surah_json_file_path = "#{@export_file_path}/surah.json"
      segments_json_file_path = "#{@export_file_path}/segments.json"

      surah_data = audio_files.map do |row|
        Hash[surah_table_column_names.map { |attr, col| [col, row.send(attr)] }]
      end

      segments_data = {}
      segments.each do |segment|
        segments_data[segment.verse_key] = {
          segments: segment.segments,
          duration_sec: segment.duration,
          duration_ms: segment.duration_ms,
          timestamp_from: segment.timestamp_from,
          timestamp_to: segment.timestamp_to
        }
      end

      File.open(surah_json_file_path, 'w') do |f|
        f << JSON.generate(surah_data, { state: JsonNoEscapeHtmlState.new })
      end

      File.open(segments_json_file_path, 'w') do |f|
        f << JSON.generate(segments_data, { state: JsonNoEscapeHtmlState.new })
      end

      @export_file_path
    end

    def export_sqlite
      db_file_path = "#{@export_file_path}.db"

      surah_table_attributes = surah_table_column_names.keys
      segment_table_attributes = segments_table_columns.keys

      surah_statement = create_sqlite_table(db_file_path, 'surah_list', surah_table_columns)
      segments_statement = create_sqlite_table(db_file_path, 'segments', segments_table_columns)

      audio_files.each do |row|
        fields = surah_table_attributes.map do |attr|
          row.send(attr)
        end
        surah_statement.execute(fields)
      end

      segments.each do |row|
        begin
          fields = segment_table_attributes.map do |attr|
            encode(attr, row.send(attr))
          end
          segments_statement.execute(fields)
        rescue Exception => e
          raise e
        end
      end

      close_sqlite_table

      db_file_path
    end

    protected

    def audio_files
      recitation.chapter_audio_files.order('chapter_id ASC')
    end

    def segments
      Audio::Segment.where(audio_recitation_id: recitation.id).order('verse_id ASC')
    end

    def surah_table_column_names
      {
        chapter_id: 'surah_number',
        audio_url: 'audio_url',
        duration: 'duration'
      }
    end

    def surah_table_columns
      {
        surah_number: 'INTEGER',
        audio_url: 'TEXT',
        duration: 'INTEGER'
      }
    end

    def segments_db_column_names
      {
        chapter_id: 'surah_number',
        verse_number: 'ayah_number',
        duration: 'duration_sec',
        timestamp_from: 'timestamp_from',
        timestamp_to: 'timestamp_to',
        segments: 'segments'
      }
    end

    def segments_table_columns
      {
        surah_number: 'INTEGER',
        ayah_number: 'INTEGER',
        duration_sec: 'INTEGER',
        timestamp_from: 'INTEGER',
        timestamp_to: 'INTEGER',
        segments: 'TEXT'
      }
    end

    def encode(col, val)
      if col == :segments
        val.to_s.gsub(/\s+/, '')
      else
        val
      end
    end
  end
end
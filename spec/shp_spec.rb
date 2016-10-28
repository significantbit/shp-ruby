require 'shp'

describe "SHP" do
  before(:all) do
    @shp = SHP::Shapefile.create("testfile", 1)
    @dbf = SHP::DBF.create("testfile")

    rnd = Random.new
    lat_range = 26.0..28.0
    lon_range = -82.0..-80.0

    (0..100).each do |field|
      @dbf.add_field("field_#{field}", 0, 254, 0)
    end

    @dbf.add_field("integer_0", 1, 2^31, 0)
    @dbf.add_field("double_0", 2, 2^31, 10)
    @dbf.add_field("null_0", 1, 2^31, 0)

    (0..2000).each do |num|
      shape = SHP::Shapefile.create_simple_object(1, 1, [rnd.rand(lon_range)], [rnd.rand(lat_range)], nil)
      @shp.write_object(-1, shape)
      shape.compute_extents
      @shp.rewind_object(shape)

      (0..100).each do |field|
        @dbf.write_string_attribute(num, field, "Record #{num} Field #{field}")
      end

      @dbf.write_integer_attribute(num, @dbf.get_field_index("integer_0"), 1337)
      @dbf.write_double_attribute(num, @dbf.get_field_index("double_0"), 1337.1337)
      @dbf.write_null_attribute(num, @dbf.get_field_index("null_0"))
    end
  end

  after(:all) do
    @dbf.close
    @shp.close

    # write .prj file
    prj_content = 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]'

    File.open("testfile.prj", "wb") { |f| f.write(prj_content) }
  end

  it 'open should open a shapefile for reading' do
    shp = SHP::Shapefile.open('testfile', 'rb')
    expect(shp).not_to eq(nil)
  end

  it 'get_info to return the shapefile info' do
    info = @shp.get_info
    expect(info[:number_of_entities]).to eq(2001)
    expect(info[:shape_type]).to eq(1)
  end

  it 'get_field_count to return the field count' do
    expect(@dbf.get_field_count).to eq(104)
  end

  it 'get_record_count to return the record count' do
    expect(@dbf.get_record_count).to eq(2001)
  end

  it 'get_field_index to return the field index' do
    expect(@dbf.get_field_index("field_1")).to eq(1)
  end

  it 'get_field_info to return the field info' do
    expect(@dbf.get_field_info(0)).to eq({name: "field_0", type: 0, width: 254, decimals: 0})
  end

  it 'read_integer_attribute to read the correct integer value' do
    expect(@dbf.read_integer_attribute(0, @dbf.get_field_index("integer_0"))).to eq(1337)
  end

  it 'read_double_attribute to read the correct double value' do
    expect(@dbf.read_double_attribute(0, @dbf.get_field_index("double_0"))).to eq(1337.1337)
  end

  it 'read_string_attribute to read the correct string value' do
    expect(@dbf.read_string_attribute(0, @dbf.get_field_index("field_0"))).to eq('Record 0 Field 0')
  end

  it 'is_attribute_null to check if an attribute is NULL' do
    expect(@dbf.is_attribute_null(0, @dbf.get_field_index("null_0"))).to eq(1)
  end

  it 'is_record_deleted to return 0 when a record has not been deleted' do
    expect(@dbf.is_record_deleted(0)).to eq(0)
  end

  it 'mark_record_deleted to mark a record as deleted' do
    expect(@dbf.mark_record_deleted(0, 1)).to eq(1)
  end

  it 'is_record_deleted to return 1 when a record has been deleted' do
    expect(@dbf.is_record_deleted(0)).to eq(1)
  end

  it 'get_native_field_type on integer to be correct' do
    expect(@dbf.get_native_field_type(@dbf.get_field_index("integer_0"))).to eq(SHP::DBF::FT_NATIVE_TYPE_INTEGER)
  end

  it 'get_native_field_type on double to be correct' do
    expect(@dbf.get_native_field_type(@dbf.get_field_index("double_0"))).to eq(SHP::DBF::FT_NATIVE_TYPE_DOUBLE)
  end

  it 'get_native_field_type on string to be correct' do
    expect(@dbf.get_native_field_type(@dbf.get_field_index("field_0"))).to eq(SHP::DBF::FT_NATIVE_TYPE_STRING)
  end

  it 'should raise an error when destroy is called twice' do
    shape = SHP::Shapefile.create_simple_object(1, 1, [-82.1], [-27.2], nil)
    expect { shape.destroy }.not_to raise_error
    expect { shape.destroy }.to raise_error(RuntimeError)
  end

  it 'should raise an error when calling a method after it has been destroyed' do
    shape = SHP::Shapefile.create_simple_object(1, 1, [-82.1], [-27.2], nil)
    expect { shape.destroy }.not_to raise_error
    expect { shape.compute_extents }.to raise_error(RuntimeError)
  end

  it 'should raise an error when calling a method after it has been closed' do
    file = SHP::Shapefile.create("testfile2", 1)
    expect { file.close }.not_to raise_error
    expect { file.get_info }.to raise_error(RuntimeError)
  end

  it 'should create object' do
    sni_office = [[-82.72932529449463, 27.93789618055838],
                  [-82.72932529449463, 27.93768765436987],
                  [-82.72909998893738, 27.93767817589719],
                  [-82.72911071777344, 27.93719003343022],
                  [-82.72869229316710, 27.93717581565543],
                  [-82.72868156433105, 27.93741277832466],
                  [-82.72886931896210, 27.93741751757274],
                  [-82.72886931896210, 27.93788670210399],
                  [-82.72932529449463, 27.93789618055838]]

    x_values = sni_office.map { |v| v[0] }
    y_values = sni_office.map { |v| v[1] }
    #type_id VALUE shapeType
    #index  VALUE shapeIndex
    #parts  VALUE numberOfParts
    #panPartStart   VALUE arrayOfPartStarts
    #nil  VALUE arrayOfPartTypes
    #x_array.count  VALUE numberOfVertices
    #x_array  VALUE arrayOfX
    #y_array  VALUE arrayOfY
    #nil  VALUE arrayOfZ
    #nil  VALUE arrayOfM)


    @shape = SHP::Shapefile.create_object(5,1, 1, [0],nil,x_values.count, x_values, y_values, nil, nil)
  end

  context 'shp' do
    before(:each) do
      sni_office = [[-82.72932529449463, 27.93789618055838],
                    [-82.72932529449463, 27.93768765436987],
                    [-82.72909998893738, 27.93767817589719],
                    [-82.72911071777344, 27.93719003343022],
                    [-82.72869229316710, 27.93717581565543],
                    [-82.72868156433105, 27.93741277832466],
                    [-82.72886931896210, 27.93741751757274],
                    [-82.72886931896210, 27.93788670210399],
                    [-82.72932529449463, 27.93789618055838]]

      x_values = sni_office.map { |v| v[0] }
      y_values = sni_office.map { |v| v[1] }

      @shp = SHP::Shapefile.create('testfile_polygons', 5)
      @shape = SHP::Shapefile.create_simple_object(5, x_values.count, x_values, y_values, nil)
      @shp.write_object(-1, @shape)
      @obj = @shp.read_object(0)
    end

    it 'should return the shape type' do
      expect(@obj.get_shape_type).to eq(5)
    end

    it 'should return the shape id' do
      expect(@obj.get_shape_id).to eq(0)
    end

    it 'should return the shape part count' do
      expect(@obj.get_shape_parts).to eq(1)
    end

    it 'should return the shape part start offsets' do
      expect(@obj.get_shape_part_starts).to eq([0])
    end

    it 'should return the shape part types' do
      expect(@obj.get_shape_part_types).to eq([5]) # [SHPP_RING]
    end

    it 'should return the vertex count' do
      expect(@obj.get_vertex_count).to eq(9)
    end

    it 'should return the x values' do
      expect(@obj.get_x).to eq([-82.72932529449463, -82.72932529449463, -82.72909998893738, -82.72911071777344, -82.7286922931671, -82.72868156433105, -82.7288693189621, -82.7288693189621, -82.72932529449463])
    end

    it 'should return the y values' do
      expect(@obj.get_y).to eq([27.93789618055838, 27.93768765436987, 27.93767817589719, 27.93719003343022, 27.93717581565543, 27.93741277832466, 27.93741751757274, 27.93788670210399, 27.93789618055838])
    end

    it 'should return the z values' do
      expect(@obj.get_z).to eq([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    end

    it 'should return the m values' do
      expect(@obj.get_z).to eq([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    end

    it 'should return the x min' do
      expect(@obj.get_x_min).to eq(-82.72932529449463)
    end

    it 'should return the y min' do
      expect(@obj.get_y_min).to eq(27.93717581565543)
    end

    it 'should return the z min' do
      expect(@obj.get_z_min).to eq(0)
    end

    it 'should return the m min' do
      expect(@obj.get_m_min).to eq(0)
    end

    it 'should return the x max' do
      expect(@obj.get_x_max).to eq(-82.72868156433105)
    end

    it 'should return the y max' do
      expect(@obj.get_y_max).to eq(27.93789618055838)
    end

    it 'should return the z max' do
      expect(@obj.get_z_max).to eq(0)
    end

    it 'should return the m max' do
      expect(@obj.get_m_max).to eq(0)
    end
  end
end

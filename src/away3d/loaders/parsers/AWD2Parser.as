package away3d.loaders.parsers {

	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.CompositeGeometry;
	import flash.utils.Dictionary;
	import away3d.core.base.CompositeSubGeomSource;
	import away3d.animators.SkeletonAnimationState;
	import away3d.animators.SkeletonAnimator;
	import away3d.animators.data.Skeleton;
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.VectorSubGeometry;
	import away3d.entities.Mesh;
	import away3d.library.assets.BitmapDataAsset;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.materials.ColorMaterial;
	import away3d.materials.DefaultMaterialBase;
	import away3d.materials.MaterialBase;

	import flash.display.Loader;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace arcane;
	
	/**
	 * AWDParser provides a parser for the AWD data type.
	 */
	public class AWD2Parser extends ParserBase
	{
		private var _byteData : ByteArray;
		private var _startedParsing : Boolean;
		private var _cur_block_id : uint;
		private var _blocks : Vector.<AWDBlock>;
		
		private var _version : Array;
		private var _compression : uint;
		private var _streaming : Boolean;
		
		private var _optimized_for_accuracy : Boolean;
		
		private var _texture_users : Object = {};
		
		private var _parsed_header : Boolean;
		private var _body : ByteArray;
		
		private var read_float : Function;
		private var read_uint : Function;
		
		public static const UNCOMPRESSED : uint = 0;
		public static const DEFLATE : uint = 1;
		public static const LZMA : uint = 2;
		
		
		
		public static const AWD_FIELD_INT8 : uint = 1;
		public static const AWD_FIELD_INT16 : uint = 2;
		public static const AWD_FIELD_INT32 : uint = 3;
		public static const AWD_FIELD_UINT8 : uint = 4;
		public static const AWD_FIELD_UINT16 : uint = 5;
		public static const AWD_FIELD_UINT32 : uint = 6;
		public static const AWD_FIELD_FLOAT32 : uint = 7;
		public static const AWD_FIELD_FLOAT64 : uint = 8;
		
		public static const AWD_FIELD_BOOL : uint = 21;
		public static const AWD_FIELD_COLOR : uint = 22;
		public static const AWD_FIELD_BADDR : uint = 23;
		
		public static const AWD_FIELD_STRING : uint = 31;
		public static const AWD_FIELD_BYTEARRAY : uint = 32;
		
		public static const AWD_FIELD_VECTOR2x1 : uint = 41;
		public static const AWD_FIELD_VECTOR3x1 : uint = 42;
		public static const AWD_FIELD_VECTOR4x1 : uint = 43;
		public static const AWD_FIELD_MTX3x2 : uint = 44;
		public static const AWD_FIELD_MTX3x3 : uint = 45;
		public static const AWD_FIELD_MTX4x3 : uint = 46;
		public static const AWD_FIELD_MTX4x4 : uint = 47;
		
		
		public var materialFactory : Function = _defaultMaterialFactory;

		private function _defaultMaterialFactory( name : String ) : DefaultMaterialBase {
			return null;
		}
		
		public var useComposite : Boolean = true;
		
		/**
		 * Creates a new AWDParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function AWD2Parser()
		{
			super(ParserDataFormat.BINARY);
			
			_blocks = new Vector.<AWDBlock>;
			_blocks[0] = new AWDBlock;
			_blocks[0].data = null; // Zero address means null in AWD
			
			_version = [];
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.toLowerCase();
			return extension == "awd";
		}
		
		
		/**
		 * @inheritDoc
		 */
		/*override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void
		{
			// apply system default
			//BitmapMaterial(mesh.material).bitmapData = defaultBitmapData;
		}*/
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean
		{
			var bytes : ByteArray = ParserUtil.toByteArray(data);
			
			if (bytes) {
				var magic : String;
				
				bytes.position = 0;
				magic = data.readUTFBytes(3);
				bytes.position = 0;
				
				if (magic == 'AWD')
					return true;
			}
			
			return false;
		}
		
		
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing() : Boolean
		{
			if(!_startedParsing) {
				_byteData = getByteData();
				_startedParsing = true;
			}
			
			if (!_parsed_header) {
				_byteData.endian = Endian.BIG_ENDIAN;
				
				//TODO: Create general-purpose parseBlockRef(requiredType) (return _blocks[addr] or throw error)
				
				// Parse header and decompress body
				parseHeader();
				switch (_compression) {
					case DEFLATE:
						_body = new ByteArray;
						_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
						_body.uncompress();
						break;
					case LZMA:
						// TODO: Decompress LZMA into _body
						dieWithError('LZMA decoding not yet supported in AWD parser.');
						break;
					case UNCOMPRESSED:
						_body = _byteData;
						break;
				}
				
				// Define which methods to use when reading floating
				// point and integer numbers respectively. This way, 
				// the optimization test and ByteArray dot-lookup
				// won't have to be made every iteration in the loop.
				read_float = _optimized_for_accuracy? _body.readDouble : _body.readFloat;
				read_uint = _optimized_for_accuracy? _body.readUnsignedInt : _body.readUnsignedShort;
			
				
				_parsed_header = true;
			}
			
			while (_body.bytesAvailable > 0 && !parsingPaused && hasTime()) {
				parseNextBlock();
			}
			
			// Return complete status
			if (_body.bytesAvailable==0) {
				return PARSING_DONE;
			}
			else return MORE_TO_PARSE;
		}
		
		private function parseHeader() : void
		{
			var flags : uint;
			var body_len : Number;
			
			// Skip magic string and parse version
			_byteData.position = 3;
			_version[0] = _byteData.readUnsignedByte();
			_version[1] = _byteData.readUnsignedByte();
			
			// Parse bit flags and compression
			flags = _byteData.readUnsignedShort();
			_streaming 					= (flags & 0x1) == 0x1;
			_optimized_for_accuracy 	= (flags & 0x2) == 0x2;
			
			
			_compression = _byteData.readUnsignedByte();
			
			// Check file integrity
			body_len = _byteData.readUnsignedInt();
			if (!_streaming && body_len != _byteData.bytesAvailable) {
				dieWithError('AWD2 body length does not match header integrity field');
			}
		}
		
		private function parseNextBlock() : void
		{
			
			var assetData : IAsset;
			var ns : uint, type : uint, len : uint;
			
			_cur_block_id = _body.readUnsignedInt();
			ns = _body.readUnsignedByte();
			type = _body.readUnsignedByte();
			len = _body.readUnsignedInt();
			
			//trace( "away3d.loaders.parsers.AWD2Parser - parseNextBlock -- ", _cur_block_id, ns, type, len );
			
			
			switch (type) {
				case 1:
					assetData = parseMeshData(len);
					break;
				case 22:
					assetData = parseContainer(len);
					break;
				case 24:
					assetData = parseMeshInstance(len);
					break;
				case 81:
					assetData = parseMaterial(len);
					break;
//				case 82:
//					assetData = parseTexture(len);
//					break;
				default:
					////trace('Ignoring block!');
					_body.position += len;
					break;
			}
			
			// Store block reference for later use
			_blocks[_cur_block_id] = new AWDBlock();
			_blocks[_cur_block_id].data = assetData;
			_blocks[_cur_block_id].id = _cur_block_id;
		}
		
		
		private function parseMaterial(blockLength : uint) : MaterialBase
		{
			var name : String;
			var type : uint;
			var props : AWDProperties;
			var mat : DefaultMaterialBase;
			var attributes : Object;
			var finalize : Boolean;
			var num_methods : uint;
			var methods_parsed : uint;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			num_methods = _body.readUnsignedByte();
			
			// Read material numerical properties
			// (1=color, 2=bitmap url, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			props = parseProperties({ 1:AWD_FIELD_INT32, 2:AWD_FIELD_BADDR, 
				11:AWD_FIELD_BOOL, 12:AWD_FIELD_FLOAT32, 13:AWD_FIELD_BOOL });
			
			methods_parsed = 0;
			while (methods_parsed < num_methods) {
				var method_type : uint;
				
				method_type = _body.readUnsignedShort();
				parseProperties(null);
				parseUserAttributes();
			}
			
			attributes = parseUserAttributes();
			
			mat = materialFactory( name );
			if( mat == null ) return null;
				
			mat.extra = attributes;
			mat.alphaThreshold = props.get(12, 0.0);
			mat.repeat = props.get(13, false);
			
			if (finalize) {
				finalizeAsset(mat, name);
			}
			
			return mat;
		}
		
		
		private function parseTexture(blockLength : uint) : BitmapDataAsset
		{
			var name : String;
			var type : uint;
			var data_len : uint;
			var asset : BitmapDataAsset;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			data_len = _body.readUnsignedInt();
			
			_texture_users[_cur_block_id.toString()] = [];
			
			// External
			if (type == 0) {
				var url : String;
				
				url = _body.readUTFBytes(data_len);
				
				addDependency(_cur_block_id.toString(), new URLRequest(url));
			}
			else {
				var data : ByteArray;
				var loader : Loader;
				
				data = new ByteArray();
				_body.readBytes(data, 0, data_len);
				
				addDependency(_cur_block_id.toString(), null, false, data);
			}
			
			// Ignore for now
			parseProperties(null);
			parseUserAttributes();
			
			
			// TODO: Don't do this. Get texture properly
			//asset = new BitmapDataAsset();
			/*
			finalizeAsset(asset, name);
			*/
			
			//pauseAndRetrieveDependencies();
			
			return asset;
		}
		
		
		
		private function parseContainer(blockLength : uint) : ObjectContainer3D
		{
			var name : String;
			var par_id : uint;
			var mtx : Matrix3D;
			var ctr : ObjectContainer3D;
			var parent : ObjectContainer3D;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			
			ctr = new ObjectContainer3D();
			ctr.transform = mtx;
			
			parent = _blocks[par_id].data as ObjectContainer3D;
			if (parent) {
				parent.addChild(ctr);
			}
			
			parseProperties(null);
			ctr.extra = parseUserAttributes();
		
			finalizeAsset(ctr, name);
			
			return ctr;
		}
		
		private function parseMeshInstance(blockLength : uint) : Mesh
		{
			var name : String;
			var mesh : Mesh, geom : Geometry;
			var par_id : uint, data_id : uint;
			var mtx : Matrix3D;
			var materials : Vector.<MaterialBase>;
			var num_materials : uint;
			var materials_parsed : uint;
			var parent : ObjectContainer3D;
			
			par_id = _body.readUnsignedInt();
			mtx = parseMatrix3D();
			name = parseVarStr();
			
			data_id = _body.readUnsignedInt();
			geom = _blocks[data_id].data as Geometry;
			
			materials = new Vector.<MaterialBase>;
			num_materials = _body.readUnsignedShort();
			materials_parsed = 0;
			while (materials_parsed < num_materials) {
				var mat_id : uint;
				mat_id = _body.readUnsignedInt();
				
				materials.push(_blocks[mat_id].data);
				
				materials_parsed++;
			}
			
			mesh = new Mesh( geom, null );
			mesh.transform = mtx;
			
			// Add to parent if one exists
			parent = _blocks[par_id].data as ObjectContainer3D;
			if (parent) {
				parent.addChild(mesh);
			}
			
			////trace( "away3d.loaders.parsers.AWD2Parser - parseMeshInstance -- ",materials.length, mesh.subMeshes.length );
			if ( (materials.length == 1 || mesh.subMeshes.length == 1) && (materials.length&mesh.subMeshes.length)>0 ) {
				mesh.material = materials[0];
			}
			else if(materials.length > 0 ){
				var i : uint;
				// Assign each sub-mesh in the mesh a material from the list. If more sub-meshes
				// than materials, repeat the last material for all remaining sub-meshes.
				for (i=0; i<mesh.subMeshes.length; i++) {
					////trace( "away3d.loaders.parsers.AWD2Parser - parseMeshInstance -- ",materials[Math.min(materials.length-1, i)] );
					mesh.subMeshes[i].material = materials[Math.min(materials.length-1, i)];
				}
			}
			
			// Ignore for now
			var props : AWDProperties = parseProperties( {2 : AWD2Parser.AWD_FIELD_BADDR} );
			
			mesh.extra = parseUserAttributes();
			
			finalizeAsset(mesh, name);
			
			return mesh;
		}
		
		
		private function parseMeshData(blockLength : uint) : Geometry
		{
			var name : String;
			var geom : Geometry;
			var num_subs : uint;
			var subs_parsed : uint;
			var joints_per_vertex : int = -1;
			var props : AWDProperties;
			var bsm : Matrix3D;
			
			// Read name and sub count
			name = parseVarStr();
			num_subs = _body.readUnsignedShort();
			
			// Read optional properties
			props = parseProperties({ 1:AWD_FIELD_MTX4x4, 2 : AWD_FIELD_BADDR }); 
			
			var bsm_data : Array = props.get(1, null);
			if (bsm_data) {
				bsm = new Matrix3D(Vector.<Number>(bsm_data));
			}
			
			var isGComposite : Boolean = false;
			var subgeoms : Array = [];

			
			
			// Loop through sub meshes
			subs_parsed = 0;
			while (subs_parsed < num_subs) {
				var isComposite : Boolean = false;
				var mat_id : uint, sm_len : uint, sm_end : uint;
				var sub_geom : VectorSubGeometry;
				var skinned_sub_geom : SkinnedSubGeometry;
				var w_indices : Vector.<Number>;
				var weights : Vector.<Number>;
				var compositeGroups : Dictionary;
				
				sub_geom = new VectorSubGeometry();
				
				sm_len = _body.readUnsignedInt();
				sm_end = _body.position + sm_len;
				
				// Ignore for now
				parseProperties(null);
				
				//trace( "away3d.loaders.parsers.AWD2Parser - parseMeshData -- ", name );
				// Loop through data streams
				while (_body.position < sm_end) {
					var idx : uint = 0;
					var str_type : uint, str_len : uint, str_end : uint;
					
					str_type = _body.readUnsignedByte();
					str_len = _body.readUnsignedInt();
					str_end = _body.position + str_len;
					
					var x:Number, y:Number, z:Number;
					
					//trace( "away3d.loaders.parsers.AWD2Parser - parseMeshData -- type", str_type );
					
					if (str_type == 1) {
						var verts : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							x = read_float();
							y = read_float();
							z = read_float();
							
							verts[idx++] = x;
							verts[idx++] = y;
							verts[idx++] = z;
						}
						sub_geom.updateVertexData(verts);
					}
					else if (str_type == 8 ) {
						isGComposite = 
						isComposite = useComposite;
						var gindices : Vector.<uint>;
						var gid : uint;
						var glen : uint;
						var k: int;
						if( useComposite ) {
							compositeGroups = new Dictionary();
							while (_body.position < str_end) {
								gid = read_uint();
								glen = read_uint();
								compositeGroups[gid] = 
								gindices = new Vector.<uint>( glen, true );
								for (k = 0; k < glen; k++) {
									gindices[k] = read_uint();
								}
							}
						} else {
							gindices = new Vector.<uint>();
							while (_body.position < str_end) {
								gid = read_uint();
								glen = read_uint();
								for (k = 0; k < glen; k++) {
									gindices[idx++] = read_uint();
								}
							}
							sub_geom.updateIndexData(gindices);
						}
					}
					else if (str_type == 2) {
						var indices : Vector.<uint> = new Vector.<uint>;
						while (_body.position < str_end) {
							indices[idx++] = read_uint();
						}
						sub_geom.updateIndexData(indices);
					}
					else if (str_type == 3) {
						var uvs : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							uvs[idx++] = read_float();
						}
						sub_geom.updateUVData(uvs);
					}
					else if (str_type == 4) {
						var normals : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							normals[idx++] = read_float();
						}
						sub_geom.autoDeriveVertexNormals = false;
						sub_geom.updateVertexNormalData(normals);
					}
					else if (str_type == 9) {
						var colors : Vector.<Number> = new Vector.<Number>;
						while (_body.position < str_end) {
							colors[idx++] = read_float();
						}
						sub_geom.updateVertexColorData(colors);
					}
					else if (str_type == 6) {
						w_indices = new Vector.<Number>;
						while (_body.position < str_end) {
							w_indices[idx++] = read_uint()*3;
						}
					}
					else if (str_type == 7) {
						weights = new Vector.<Number>;
						while (_body.position < str_end) {
							weights[idx++] = read_float();
						}
					}
					else {
						_body.position = str_end;
					}
				}
					
				// Ignore sub-mesh attributes for now
				parseUserAttributes();
				
				// If there were weights and joint indices defined, this
				// is a skinned mesh and needs to be built from skinned
				// sub-geometries, so copy data across.
				if (w_indices && weights) {
					//trace( "away3d.loaders.parsers.AWD2Parser - parseMeshData -- weighted vbuff", name);
					joints_per_vertex = weights.length / sub_geom.numVertices;
					skinned_sub_geom = new SkinnedSubGeometry( joints_per_vertex );
					skinned_sub_geom.updateVertexData(sub_geom.vertexData);
					skinned_sub_geom.updateIndexData(sub_geom.indexData);
					skinned_sub_geom.updateUVData(sub_geom.UVData);
					skinned_sub_geom.updateVertexNormalData(sub_geom.vertexNormalData);
					skinned_sub_geom.updateJointIndexData(w_indices);
					skinned_sub_geom.updateJointWeightsData(weights);
					sub_geom = skinned_sub_geom;
					
				} else if( isComposite ) {
					var composite : CompositeSubGeomSource = new CompositeSubGeomSource();
					composite.updateVertexData(sub_geom.vertexData);
					composite.updateUVData(sub_geom.UVData);
					composite.updateVertexNormalData(sub_geom.vertexNormalData);
					composite.setGroups( compositeGroups );
					sub_geom = composite;
				}
				
				subs_parsed++;
				subgeoms.push( sub_geom );
			}
			
			
			if( isGComposite )
				geom = new CompositeGeometry();
			else
				geom = new Geometry();
			
			for (var i : int = 0; i < subgeoms.length; i++) {
				geom.addSubGeometry( subgeoms[i] );
				if( subgeoms[i] is CompositeSubGeomSource )
					geom.addSubGeometry( subgeoms[i].createSub() );
					
			}			
			
			parseUserAttributes();
			
			finalizeAsset(geom, name);
			
			return geom;
		}
		
		
		private function parseVarStr() : String
		{
			var len : uint = _body.readUnsignedShort();
			return _body.readUTFBytes(len);
		}
		
		
		// TODO: Improve this by having some sort of key=type dictionary
		private function parseProperties(expected : Object) : AWDProperties
		{
			var list_end : uint;
			var list_len : uint;
			var props : AWDProperties;
			
			props = new AWDProperties();
			
			list_len = _body.readUnsignedInt();
			list_end = _body.position + list_len;
			
			if (expected) {
				while (_body.position < list_end) {
					var len : uint;
					var key : uint;
					var type : uint;
					
					key = _body.readUnsignedShort();
					len = _body.readUnsignedShort();
					if (expected.hasOwnProperty(key)) {
						type = expected[key];
						props.set(key, parseAttrValue(type, len));
					}
					else {
						_body.position += len;
					}
					
				}
			} else {
				_body.position = list_end;
			}
			
			return props;
		}
		
		private function parseUserAttributes() : Object
		{
			var attributes : Object;
			var list_len : uint;
			
			list_len = _body.readUnsignedInt();
			if (list_len > 0) {
				var list_end : uint;
				
				attributes = {};
				
				list_end = _body.position + list_len;
				while (_body.position < list_end) {
					var ns_id : uint;
					var attr_key : String;
					var attr_type : uint;
					var attr_len : uint;
					var attr_val : *;
					
					// TODO: Properly tend to namespaces in attributes
					ns_id = _body.readUnsignedByte();
					attr_key = parseVarStr();
					attr_type = _body.readUnsignedByte();
					attr_len = _body.readUnsignedShort();
					
					switch (attr_type) {
						case AWD_FIELD_STRING:
							attr_val = _body.readUTFBytes(attr_len);
							break;
						default:
							attr_val = 'unimplemented attribute type '+attr_type;
							_body.position += attr_len;
							break;
					}
					
					attributes[attr_key] = attr_val;
				}
			}
			
			return attributes;
		}
		
		private function parseAttrValue(type : uint, len : uint) : *
		{
			var elem_len : uint;
			var read_func : Function;
			
			switch (type) {
				case AWD_FIELD_INT8:
					elem_len = 1;
					read_func = _body.readByte;
					break;
				case AWD_FIELD_INT16:
					elem_len = 2;
					read_func = _body.readShort;
					break;
				case AWD_FIELD_INT32:
					elem_len = 4;
					read_func = _body.readInt;
					break;
				case AWD_FIELD_BOOL:
				case AWD_FIELD_UINT8:
					elem_len = 1;
					read_func = _body.readUnsignedByte;
					break;
				case AWD_FIELD_UINT16:
					elem_len = 2;
					read_func = _body.readUnsignedShort;
					break;
				case AWD_FIELD_UINT32:
				case AWD_FIELD_BADDR:
					elem_len = 4;
					read_func = _body.readUnsignedInt;
					break;
				case AWD_FIELD_FLOAT32:
					elem_len = 4;
					read_func = _body.readFloat;
					break;
				case AWD_FIELD_FLOAT64:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
				case AWD_FIELD_VECTOR2x1:
				case AWD_FIELD_VECTOR3x1:
				case AWD_FIELD_VECTOR4x1:
				case AWD_FIELD_MTX3x2:
				case AWD_FIELD_MTX3x3:
				case AWD_FIELD_MTX4x3:
				case AWD_FIELD_MTX4x4:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
			}
			
			if (elem_len < len) {
				var list : Array;
				var num_read : uint;
				var num_elems : uint;
				
				list = [];
				num_read = 0;
				num_elems = len / elem_len;
				while (num_read < num_elems) {
					list.push(read_func());
					num_read++;
				}
				
				return list;
			}
			else {
				var val : *;
				
				val = read_func();
				return val;
			}
		}
		
		private function parseMatrix2D() : Matrix
		{
			var mtx : Matrix;
			var mtx_raw : Vector.<Number> = parseMatrixRawData(6);
			
			mtx = new Matrix(mtx_raw[0], mtx_raw[1], mtx_raw[2], mtx_raw[3], mtx_raw[4], mtx_raw[5]);
			return mtx;
		}
		
		private function parseMatrix3D() : Matrix3D
		{
			var mtx : Matrix3D = new Matrix3D(parseMatrixRawData());
			return mtx;
		}
		
		private function parseMatrixRawData(len : uint = 16) : Vector.<Number>
		{
			var i : uint;
			var mtx_raw : Vector.<Number> = new Vector.<Number>;
			for (i=0; i<len; i++) {
				mtx_raw[i] = read_float();
			}
			
			return mtx_raw;
		}
	}
}


internal class AWDBlock
{
	public var id : uint;
	public var data : *;
}

internal dynamic class AWDProperties
{
	public function set(key : uint, value : *) : void
	{
		this[key.toString()] = value;
	}
	
	public function get(key : uint, fallback : *) : *
	{
		if (this.hasOwnProperty(key.toString()))
			return this[key.toString()];
		else return fallback;
	}
}



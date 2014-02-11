package away3d.textures {
	import com.instagal.Tex;
	import flash.display3D.Context3DTextureFormat;
	import flash.utils.ByteArray;
	/**
	 * @author Pierre Lepers
	 * away3d.textures.Atf
	 */
	public class Atf {
		
				
		/**
		 * 24bit RGB format
		 */
		public static const RGB888 : uint = 0;
		/**
		 * 32bit RGBA format
		 */
		public static const RGBA88888 : uint = 1;
		/**
		 * block based compression format (DXT1 + PVRTC + ETC1)
		 */
		public static const Compressed : uint = 2;
		
				/**
		 * 2D texture
		 */
		public static const NORMAL : uint = 0;

		/**
		 * cubic texture
		 */
		public static const CUBE_MAP : uint = 1;



		private var _input : ByteArray;

		public function get bytes() : ByteArray {
			return _input;
		}

		public function Atf(input : ByteArray) {
			_input = input;
			_read(input);
		}
		
		
		public function getSamplerType() : uint {
			if( format < 2 ) return Tex.RGBA;
			if( format < 4 ) return Tex.DXT1;
			return Tex.DXT5;
		}

		public function getTextureFormat() : String {
			if( format < 2 ) return Context3DTextureFormat.BGRA;
			if( format < 4 ) return Context3DTextureFormat.COMPRESSED;
			return Context3DTextureFormat.COMPRESSED_ALPHA;
		}

		private function _read(input : ByteArray) : void {
			var sign : String = input.readUTFBytes( 3 );
			if( sign != MAGIC )
				throw new Error( "ATF parsing error, unknown format " + sign );
			
			length = (input.readUnsignedByte( ) << 16) + (input.readUnsignedByte( ) << 8) + input.readUnsignedByte( );
			
			var tdata : uint = input.readUnsignedByte( );
			type = tdata >> 7; 		// UB[1]
			format = tdata & 0x7f;	// UB[7]

			width = Math.pow( 2, input.readUnsignedByte( ) );
			height = Math.pow( 2, input.readUnsignedByte( ) );
			
			count = input.readUnsignedByte( );
		}
		
		public var type : uint;
		
		public var format : uint;
		
		public var count : uint;
		
		public var length : uint;
		
		public var width : uint;
		public var height : uint;


		
	}
}

const MAGIC : String = "ATF";

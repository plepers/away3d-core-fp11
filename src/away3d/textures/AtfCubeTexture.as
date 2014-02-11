package away3d.textures {

	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.TextureBase;
	/**
	 * @author Pierre Lepers
	 * away3d.textures.AtfTexture
	 */
	public class AtfCubeTexture extends CubeTextureBase implements IAtfTexture {

		private var _atf : Atf;
		private var _async : Boolean = false;

		public function AtfCubeTexture(atf : Atf = null ) {
			super();
			if( atf != null ) setAtf( atf );
		}

		public function setAtf( atf : Atf ) : void {
			_atf = atf;
			_samplerType = atf.getSamplerType();
			
			invalidateContent();
			setSize( atf.width, atf.height );
			
		}
		
		override protected function createTexture(context : Context3D) : TextureBase
		{
			return context.createCubeTexture(_width, _atf.format == Atf.Compressed ? Context3DTextureFormat.COMPRESSED : Context3DTextureFormat.BGRA, false);
		}
		
		override protected function uploadContent(texture : TextureBase) : void
		{
			var tex : CubeTexture = texture as CubeTexture;
			tex.uploadCompressedTextureFromByteArray( _atf.bytes, 0, _async );
		}

		public function uploadContentAsync( stage3DProxy : Stage3DProxy ) : TextureBase {
			_async = true;
			var res : TextureBase = getTextureForStage3D(stage3DProxy);
			_async = false;
			return res;
		}

	}
}

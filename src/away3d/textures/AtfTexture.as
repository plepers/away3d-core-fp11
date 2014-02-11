package away3d.textures {

	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	/**
	 * @author Pierre Lepers
	 * away3d.textures.AtfTexture
	 */
	public class AtfTexture extends Texture2DBase implements IAtfTexture {

		private var _atf : Atf;
		private var _async : Boolean = false;

		public function AtfTexture( atf : Atf = null ) {
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
			return context.createTexture(_width, _height, _atf.getTextureFormat() , false);
		}
		
		override protected function uploadContent(texture : TextureBase) : void
		{
			var tex : Texture = texture as Texture;
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

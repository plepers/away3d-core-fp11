package away3d.textures {

	import away3d.library.assets.IAsset;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.textures.TextureBase;
	/**
	 * @author Pierre Lepers
	 * away3d.textures.IAtfTExture
	 */
	public interface IAtfTexture extends IAsset{

		function setAtf(atf : Atf) : void;

		function uploadContentAsync( stage3DProxy : Stage3DProxy ) : TextureBase;
		
	}
}

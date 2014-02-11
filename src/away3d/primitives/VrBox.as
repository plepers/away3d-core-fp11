package away3d.primitives
{

	import com.nissan.matlib.default.VrBoxMaterial;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.partition.EntityNode;
	import away3d.core.partition.NodeBase;
	import away3d.core.partition.VrBoxNode;
	import away3d.materials.SkyBoxMaterial;
	import away3d.textures.CubeTextureBase;

	import nissan.cc3d.engine.scene.MaskedEntityCollector;
	import nissan.cc3d.engine.scene.MaskedPartition;

	import flash.geom.Matrix3D;

	use namespace arcane;

	/**
	 * A SkyBox class is used to render a sky in the scene. It's always considered static and 'at infinity', and as
	 * such it's always centered at the camera's position and sized to exactly fit within the camera's frustum, ensuring
	 * the sky box is always as large as possible without being clipped.
	 */
	public class VrBox extends SkyBox
	{
		
		
		/**
		 * Create a new SkyBox object.
		 * @param cubeMap The CubeMap to use for the sky box's texture.
		 */
		public function VrBox(cubeMap : CubeTextureBase)
		{
			super(cubeMap);
			partition = new MaskedPartition( new NodeBase(), MaskedEntityCollector.VR_FILTER );
		}
		
		override protected function createMaterial(cubeMap : CubeTextureBase) : SkyBoxMaterial {
			return new VrBoxMaterial(cubeMap);
		}
		
		override protected function createEntityPartitionNode() : EntityNode
		{
			return new VrBoxNode(this);
		}

	
		/**
		 * Restore classic transformation
		 * Scale is manual
		 */
		override public function pushModelViewProjection(camera : Camera3D) : void
		{
			if (++_mvpIndex == _stackLen) {
				_mvpTransformStack[_mvpIndex] = new Matrix3D();
				_stackLen++;
			}
			
			_mvpUnsafe = _mvpTransformStack[_mvpIndex];
			_mvpUnsafe.copyFrom(sceneTransform);
			_mvpUnsafe.append(camera.viewProjection);
			_mvpUnsafe.copyColumnTo(3, _POS);
			_zIndices[_mvpIndex] = -_POS.z;
			
//			_mvpUnsafe = _mvpTransformStack[_mvpIndex];
//			_mvpUnsafe.copyFrom(sceneTransform);
//			_mvpUnsafe.position = camera.position;
//			_mvpUnsafe.append(camera.viewProjection);
			
		}


		
	}
}

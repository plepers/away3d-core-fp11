package away3d.core.partition
{
	import away3d.cameras.Camera3D;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.primitives.SkyBox;

	/**
	 * SkyBoxNode is a space partitioning leaf node that contains a SkyBox object.
	 */
	public class VrBoxNode extends EntityNode
	{
		private var _skyBox : SkyBox;

		/**
		 * Creates a new SkyBoxNode object.
		 * @param skyBox The SkyBox to be contained in the node.
		 */
		public function VrBoxNode(skyBox : SkyBox)
		{
			super(skyBox);
			_skyBox = skyBox;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser : PartitionTraverser) : void
		{
			if (traverser.enterNode(this)) {
				super.acceptTraverser(traverser);
				traverser.applyRenderable(_skyBox);
			}
			traverser.leaveNode(this);
		}

		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(camera : Camera3D) : Boolean
		{
			_skyBox.pushModelViewProjection(camera);
			return true;//_skyBox.bounds.isInFrustum(_skyBox.getModelViewProjectionUnsafe());
		}
	}
}
package away3d.materials.passes {

	import away3d.arcane;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVO;

	/**
	 * @author Pierre Lepers
	 * away3d.materials.passes.MethodSet
	 */
	use namespace  arcane;
	final public class MethodSet {

		public var method : EffectMethodBase;
		public var data : MethodVO;

		public function MethodSet(method : EffectMethodBase) {
			this.method = method;
			data = method.createMethodVO();
		}
	}
}

package away3d.animators
{
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.animators.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;

	/**
	 * The animation data set used by skeleton-based animators, containing skeleton animation state data.
	 * 
	 * @see away3d.animators.SkeletonAnimator
	 * @see away3d.animators.SkeletonAnimationState
	 */
	public class SkeletonAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _jointsPerVertex : uint;
		
		/**
		 * Returns the amount of skeleton joints that can be linked to a single vertex via skinned weight values. For GPU-base animation, the 
		 * maximum allowed value is 4.
		 */
		public function get jointsPerVertex() : uint
		{
			return _jointsPerVertex;
		}
		
		/**
		 * Creates a new <code>SkeletonAnimationSet</code> object.
		 * 
		 * @param jointsPerVertex Sets the amount of skeleton joints that can be linked to a single vertex via skinned weight values. For GPU-base animation, the maximum allowed value is 4. Defaults to 4.
		 */
		public function SkeletonAnimationSet(jointsPerVertex : uint = 4)
		{
			_jointsPerVertex = jointsPerVertex;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : ShaderChunk
		{
			var len : uint = sourceRegisters.length;

			var indexOffset0 : uint = pass.numUsedVertexConstants;
			var indexOffset1 : uint = indexOffset0 + 1;
			var indexOffset2 : uint = indexOffset0 + 2;
			var indexStream : uint = a0 + pass.numUsedStreams;
			var weightStream : uint = a0 + (pass.numUsedStreams + 1);
			var indices : Array = [ indexStream  ^x, indexStream  ^y, indexStream  ^z, indexStream  ^w ];
			var weights : Array = [ weightStream ^x, weightStream ^y, weightStream ^z, weightStream ^w ];
			var tp1 : uint = findTempReg(targetRegisters);
			var tp2 : uint = findTempReg(targetRegisters, tp1 );
			var code : ShaderChunk = new ShaderChunk();
			var dot : Function = code.dp4;
			

			for (var i : uint = 0; i < len; ++i) {

				var src : uint = sourceRegisters[i];

				for (var j : uint = 0; j < _jointsPerVertex; ++j) {
					dot.call( code, tp1 ^x, src    , c(indices[j]) + indexOffset0 );
					dot.call( code, tp1 ^y, src    , c(indices[j]) + indexOffset1 );
					dot.call( code, tp1 ^z, src    , c(indices[j]) + indexOffset2 );
					code.mov(       tp1 ^w, src ^w );
					code.mul(       tp1   , tp1  , weights[j] );	// apply weight

					// add or mov to target. Need to write to a temp reg first, because an output can be a target
					if (j == 0) 
						code.mov( tp2 , tp1 );
					else 
						code.add( tp2, tp2, tp1 );
				}
				// switch to dp3 once positions have been transformed, from now on, it should only be vectors instead of points
				dot = code.dp3;
				code.mov( targetRegisters[i].value(), tp2 );
			}

			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			var streamOffset : uint = pass.numUsedStreams;

			stage3DProxy.setSimpleVertexBuffer(streamOffset, null, null, 0);
			stage3DProxy.setSimpleVertexBuffer(streamOffset + 1, null, null, 0);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function addState(stateName:String, animationState:IAnimationState):void
		{
			super.addState(stateName, animationState);
			
			animationState.addOwner(this, stateName);
		}
	}
}

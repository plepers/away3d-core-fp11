package away3d.animators
{
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;

	import flash.utils.Dictionary;

	/**
	 * The animation data set used by vertex-based animators, containing vertex animation state data.
	 * 
	 * @see away3d.animators.VertexAnimator
	 * @see away3d.animators.VertexAnimationState
	 */
	public class VertexAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _numPoses : uint;
		private var _blendMode : String;
		private var _streamIndices : Dictionary = new Dictionary(true);
		private var _useNormals : Dictionary = new Dictionary(true);
		private var _useTangents : Dictionary = new Dictionary(true);
		private var _uploadNormals : Boolean;
		private var _uploadTangents : Boolean;

		/**
		 * Returns the number of poses made available at once to the GPU animation code.
		 */
		public function get numPoses() : uint
		{
			return _numPoses;
		}
		
		/**
		 * Returns the active blend mode of the vertex animator object.
		 */
		public function get blendMode() : String
		{
			return _blendMode;
		}
		
		/**
		 * Returns whether or not normal data is used in last set GPU pass of the vertex shader. 
		 */
		public function get useNormals() : Boolean
		{
			return _uploadNormals;
		}
		
		/**
		 * Creates a new <code>VertexAnimationSet</code> object.
		 * 
		 * @param numPoses The number of poses made available at once to the GPU animation code.
		 * @param blendMode Optional value for setting the animation mode of the vertex animator object.
		 * 
		 * @see away3d.animators.data.VertexAnimationMode
		 */
		public function VertexAnimationSet(numPoses : uint = 2, blendMode : String = "absolute" )
		{
			super();
			_numPoses = numPoses;
			_blendMode = blendMode;
			
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Vector.<uint>, targetRegisters : Vector.<uint>) : ShaderChunk
		{
			if (_blendMode == VertexAnimationMode.ABSOLUTE)
				return getAbsoluteAGALCode(pass, sourceRegisters, targetRegisters);
			else
				return getAdditiveAGALCode(pass, sourceRegisters, targetRegisters);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			_uploadNormals = _useNormals[pass];
			_uploadTangents = _useTangents[pass];
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			var index : int = _streamIndices[pass];
			stage3DProxy.setSimpleVertexBuffer(index, null, null);
			if (_uploadNormals)
				stage3DProxy.setSimpleVertexBuffer(index + 1, null, null);
			if (_uploadTangents)
				stage3DProxy.setSimpleVertexBuffer(index + 2, null, null);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function addState(stateName:String, animationState:IAnimationState):void
		{
			super.addState(stateName, animationState);
			
			animationState.addOwner(this, stateName);
		}
		
		/**
		 * Generates the vertex AGAL code for absolute blending.
		 */
		private function getAbsoluteAGALCode(pass : MaterialPassBase, sourceRegisters : Vector.<uint>, targetRegisters : Vector.<uint>) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var temp1 : uint = findTempReg(targetRegisters);
			var temp2 : uint = findTempReg(targetRegisters, temp1);
			
			var regs : Array = [x, y, z, w];
			var len : uint = sourceRegisters.length;
			var constantReg : uint = c0 + pass.numUsedVertexConstants;
			var useTangents : Boolean = _useTangents[pass] = len > 2;
			_useNormals[pass] = len > 1;

			if (len > 2) len = 2;
			var streamIndex : uint = _streamIndices[pass] = pass.numUsedStreams;

			for (var i : uint = 0; i < len; ++i) {
				code.mul( temp1, sourceRegisters[i] , constantReg ^ regs[0]  );

				for (var j : uint = 1; j < _numPoses; ++j) {
					code.mul( temp2 , a0 + streamIndex , constantReg  ^regs[j] );

					if (j < _numPoses - 1)
						code.add( temp1 , temp1 , temp2 );

					++streamIndex;
				}

				code.add( targetRegisters[i], temp1 ,temp2 );
			}

			// add code for bitangents if tangents are used
			if (useTangents) {
				code.dp3(  temp1 ^x,  sourceRegisters[uint(2)] , targetRegisters[uint(1)] );
				code.mul(  temp1    , targetRegisters[uint(1)] , temp1 ^x			  );
				code.sub(  targetRegisters[uint(2)] ,sourceRegisters[uint(2)] ,temp1 );
			}
			
			return code;
		}
		
		/**
		 * Generates the vertex AGAL code for additive blending.
		 */
		private function getAdditiveAGALCode(pass : MaterialPassBase, sourceRegisters : Vector.<uint>, targetRegisters : Vector.<uint>) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var len : uint = sourceRegisters.length;
			var regs : Array = [x, y, z, w];
			var temp1 : uint = findTempReg(targetRegisters);
			var k : uint;
			var useTangents : Boolean = _useTangents[pass] = len > 2;
			var useNormals : Boolean = _useNormals[pass] = len > 1;
			var streamIndex : uint = _streamIndices[pass] = pass.numUsedStreams;

			if (len > 2) len = 2;

			code.mov( targetRegisters[0], sourceRegisters[0] );
			if (useNormals) 
				code.mov( targetRegisters[1] , sourceRegisters[1] );

			for (var i : uint = 0; i < len; ++i) {
				for (var j : uint = 0; j < _numPoses; ++j) {
					code.mul( temp1 , a0 + (streamIndex + k)  , c0 + pass.numUsedVertexConstants ^ regs[j] );
					code.add( targetRegisters[i] , targetRegisters[i] , temp1 );
					k++;
				}
			}

			if (useTangents) {
				code.dp3( temp1 ^x, sourceRegisters[uint(2)] ,targetRegisters[uint(1)] );
				code.mul( temp1 ,   targetRegisters[uint(1)] ,temp1 ^x );
				code.sub( targetRegisters[uint(2)] ,sourceRegisters[uint(2)], temp1 );
			}

			return code;
		}
	}
}

<!-- Generische Modal-Wrapper-Komponente -->
<template>
  <Teleport to="body">
    <div v-if="modelValue" class="modal-backdrop" @click.self="$emit('update:modelValue', false)">
      <div class="modal-box" :style="wide ? 'max-width: 48rem' : ''">
        <slot />
      </div>
    </div>
  </Teleport>
</template>

<script setup>
defineProps({
  modelValue: Boolean,
  wide: { type: Boolean, default: false },
})
defineEmits(['update:modelValue'])
</script>

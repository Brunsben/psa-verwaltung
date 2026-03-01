<template>
  <transition name="fade">
    <div v-if="toast.show"
      :class="['fixed top-4 right-4 z-50 px-4 py-3 rounded-xl shadow-2xl text-white text-sm font-medium max-w-xs flex items-center gap-2',
        toast.type === 'error' ? 'bg-red-600' : 'bg-emerald-600']">
      <i :class="toast.type === 'error' ? 'ph ph-warning' : 'ph ph-check'"></i>
      {{ toast.msg }}
    </div>
  </transition>
</template>

<script setup>
import { toast } from '../../store.js'
</script>
